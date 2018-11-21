# frozen_string_literal: true

class Graph
  def initialize
    @g = {} # the graph // {node => { edge1 => weight, edge2 => weight}, node2 => ...
    @nodes = []
    @INFINITY = 1 << 64
  end

  # s= source, t= target, w= weight
  def add_edge s, t, w
    if !@g.key?(s)
      @g[s] = { t => w }
    else
      @g[s][t] = w
    end

    # Begin code for non directed graph (inserts the other edge too)

    if !@g.key?(t)
      @g[t] = { s => w }
    else
      @g[t][s] = w
    end

    # End code for non directed graph (ie. deleteme if you want it directed)

    @nodes << s unless @nodes.include?(s)
    @nodes << t unless @nodes.include?(t)
  end

  def show
    p @g
  end

  # Dijkstra's shortest path algorithm
  # implemented based on wikipedia's pseudocode: http://en.wikipedia.org/wiki/Dijkstra's_algorithm
  def dijkstra s
    @d = {}
    @prev = {}

    @nodes.each do |i|
      @d[i] = @INFINITY
      @prev[i] = -1
    end

    @d[s] = 0
    q = @nodes.compact
    until q.empty?
      u = nil
      q.each do |min|
        u = min if !u || (@d[min] && (@d[min] < @d[u]))
      end
      break if @d[u] == @INFINITY

      q -= [u]
      @g[u].keys.each do |v|
        alt = @d[u] + @g[u][v]
        if alt < @d[v]
          @d[v] = alt
          @prev[v] = u
        end
      end
    end
  end

  # To print the full shortest route to a node
  def print_path dest
    print_path @prev[dest] if @prev[dest] != -1
    print ">#{dest}"
  end

  # Gets all shortests paths using dijkstra

  def shortest_paths s
    dijkstra s
    puts "Source: #{s}"
    @nodes.each do |dest|
      puts "\nTarget: #{dest}"
      print_path dest
      if @d[dest] != @INFINITY
        puts "\nDistance: #{@d[dest]}"
      else
        puts "\nNO PATH"
      end
    end
  end

  def add_path dest
    add_path @prev[dest] if @prev[dest] != -1
    @path << dest
  end

  # get the shortest path between two nodes
  def shortest_path s, d
    dijkstra s
    @path = []
    add_path d
    @path
  end

  def adjacent_node n
    @g[n].keys
  end
end
