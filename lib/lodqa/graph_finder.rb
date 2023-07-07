# frozen_string_literal: true

#
# An instance of the class searches the SPARQL endpoint for a pseudo graph pattern.
#
require 'json'
require 'sparql_client/endpoint_temporary_error'

module Lodqa
  class GraphFinder
    # This constructor takes the URL of an end point to be searched
    # optionally options can be passed to the server of the end point.
    def initialize endpoint, graph_uri, options
      @endpoint = endpoint
      @graph_uri = graph_uri
      @ignore_predicates = options[:ignore_predicates] || []
      @sortal_predicates = options[:sortal_predicates] || []
      @max_hop = options[:max_hop] || 2
      @sparql_limit = options[:sparql_limit] || 100
      @answer_limit = options[:answer_limit] || 10
    end

    # Genenerate bgps and SPARQLs of each bgp.
    def sparqls_of anchored_pgp
      bgps(anchored_pgp).each { |bgp| yield [bgp, compose_sparql(bgp, anchored_pgp)] }
    end

    private

    # It generates bgps by applying variation operations to the pgp.
    # The option _max_hop_ specifies the maximum number of hops to be searched.
    def bgps pgp
      Enumerator.new do |y|
        generate_inverse_variations(
          generate_split_variations(
            generate_instantiation_variations(pgp),
            @max_hop
          )
        )
          .each_with_index do |bgp, idx|
            break if idx > @sparql_limit

            y << bgp
          end
      end
    end

    def compose_sparql bgp, pgp
      nodes = pgp[:nodes]

      # get the variables
      variables = bgp.flatten.uniq - nodes.keys.map(&:to_s)

      # initialize the query
      query  = "SELECT #{variables.map { |v| "?#{v}" }.join(' ')}\n"
      query += "FROM <#{@graph_uri}>\n" if @graph_uri.present?
      query += 'WHERE {'

      # stringify the bgp
      query += "#{bgp.map do |tp|
        tp.map do |e|
          nodes.key?(e.to_sym) ? "<#{nodes[e.to_sym][:term]}>" : "?#{e}"
        end.join(' ')
      end.join(' . ')} ."

      ## constraints on x-variables (including i-variables)
      x_variables = variables.dup.keep_if { |v| (v[0] == 'x') || (v[0] == 'i') }

      # x-variables to be bound to IRIs
      query += " FILTER (#{x_variables.map { |v| "isIRI(?#{v})" }.join(' && ')})" unless x_variables.empty?

      # x-variables to be bound to different IRIs
      x_variables.combination(2) { |c| query += " FILTER (#{"?#{c[0]}"} != #{"?#{c[1]}"})" } if x_variables.length > 1

      ## constraintes on p-variables
      p_variables = variables.dup.keep_if { |v| v[0] == 'p' }

      # initialize exclude predicates
      ex_predicates = []

      # filter out ignore predicates
      ex_predicates += @ignore_predicates

      # filter out sotral predicates
      ex_predicates += @sortal_predicates

      p_variables.each { |v| query += %| FILTER (str(?#{v}) NOT IN (#{ex_predicates.map { |s| "\"#{s}\"" }.join(', ')}))| } unless ex_predicates.empty?

      ## constraintes on s-variables
      s_variables = variables.dup.keep_if { |v| v[0] == 's' }

      # s-variables to be bound to sortal predicates
      s_variables.each { |v| query += %| FILTER (str(?#{v}) IN (#{@sortal_predicates.map { |s| "\"#{s}\"" }.join(', ')}))| }

      # query += "}"
      query += "} LIMIT #{@answer_limit}"
    end

    def generate_split_variations bgps, max_hop = 2
      Enumerator.new do |sbgps|
        bgps.each do |bgp|
          sortal_tps, non_sortal_tps = bgp.partition { |tp| tp[1].start_with? 's' }
          (1..max_hop).to_a.repeated_permutation(non_sortal_tps.length) do |split_scheme|
            split_tps = generate_split_tps(non_sortal_tps, split_scheme)
            sbgps << (sortal_tps + split_tps)
          end
        end
      end
    end

    def generate_split_tps tps, split_scheme
      split_tps = []
      tps.each_with_index do |tp, i|
        x_variables = (1...split_scheme[i]).collect { |j| "x#{i}#{j}".to_s }
        p_variables = (1..split_scheme[i]).collect { |j| "p#{i}#{j}".to_s }

        # terms including x_variables and the initial and the final terms
        terms = [tp[0], x_variables, tp[2]].flatten

        # triple patterns
        stps = (0...p_variables.length).collect { |j| [terms[j], p_variables[j], terms[j + 1]] }
        split_tps += stps
      end
      split_tps
    end

    # make variations by inversing each triple pattern
    def generate_inverse_variations bgps
      Enumerator.new do |rbgps|
        bgps.each do |bgp|
          sortal_tps, non_sortal_tps = bgp.partition { |tp| tp[1].start_with? 's' }

          [false, true].repeated_permutation(non_sortal_tps.length) do |inverse_scheme|
            rbgps << (sortal_tps + non_sortal_tps.map.with_index { |tp, i| inverse_scheme[i] ? tp.reverse : tp })
          end
        end
      end
    end

    # make variations by instantiating terms
    def generate_instantiation_variations pgp
      return [] if pgp[:edges].empty?

      iids = instantiation_ids pgp
      bgps = [bgp(pgp)]

      instantiated_BGPs(iids, bgps, pgp[:focus])
    end

    def instantiation_ids pgp
      iids = {}
      queue = Queue.new
      pgp[:nodes].each do |id, node|
        class?(node[:term]) do |err, is_class|
          iid = is_class ? "i#{id}" : nil
          queue.push [err, id, iid]
        end
      end

      # Separate loops to send HTTP requests in parallel.
      # rubocop:disable Style:CombinableLoops
      pgp[:nodes].each do
        err, id, iid = queue.pop
        raise err if err

        iids[id] = iid unless iid.nil?
      end
      # rubocop:enable Style:CombinableLoops

      iids
    end

    def bgp pgp
      connections = pgp[:edges]
      connections.map.with_index { |c, i| [c[:subject].to_sym, "p#{i + 1}".to_sym, c[:object].to_sym] }
    end

    def instantiated_BGPs iids, bgps, focus_id
      Enumerator.new do |ibgps|
        [false, true].repeated_permutation(iids.keys.length) do |instantiate_scheme|
          # id of the terms to be instantiated
          itids = iids.keys.keep_if.with_index { |_t, i| instantiate_scheme[i] }
          next unless itids.include?(focus_id.to_sym)

          if bgps.empty? && !itids.empty?
            ibgp = itids.map { |t| [iids[t], "s#{t}", t] }
            ibgps << ibgp
          else
            bgps.each do |bgp|
              # initialize the instantiated bgp with the triple patterns for term instantiation
              ibgp = itids.map { |t| [iids[t].to_s, "s#{t}", t.to_s] }

              # add update triples
              bgp.each { |tp| ibgp << tp.map { |e| itids.include?(e) ? iids[e].to_s : e.to_s } }

              ibgps << ibgp
            end
          end
        end
      end
    end

    def uri? term
      term.start_with?('http://')
    end

    def class? term
      yield(false) unless /^http:/ =~ term

      @endpoint.query_async(sparql_for(term)) do |err, result|
        yield([err, result ? !result.empty? : false])
      end
    end

    def sparql_for term
      sparql  = "SELECT ?p\n"
      sparql += "FROM <#{@graph_uri}>\n" if @graph_uri.present?
      sparql += "WHERE {?s ?p <#{term}> FILTER (str(?p) IN (#{@sortal_predicates.map { |s| "\"#{s}\"" }.join(', ')}))} LIMIT 1"
      sparql
    end

    def stringify_term t
      if t.instance_of?(RDF::URI)
        %(<#{t}>)
      elsif t.instance_of?(RDF::Literal)
        if t.datatype.to_s == 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString'
          %("#{t}"@en)
        else
          t.to_s
        end
      else
        %(?#{t})
      end
    end

    # the sparql-client gem does not support FILTER pattern
    def _compose_sparql x_variables, p_variables, bgp
      query = @endpoint.select(*p_variables, *x_variables).where(*bgp).limit(10)
      query.to_s
    end
  end
end
