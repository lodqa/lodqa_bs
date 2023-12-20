# frozen_string_literal: true

# Search for Chat GPT Plugin API
class ChatGptSearch
  include CanStartSearch

  def initialize query, target = nil
    @query = query
    @targets = if target.nil?
      Lodqa::Sources.targets
    else
      [target]
    end
  end

  # This is simple prototype search.
  # Only do start search job.
  # Do not do callback.
  # Do not do contextualization.
  def run
    pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern @query

    duplicated_pgp = PseudoGraphPattern.equals_in pgp, target
    return duplicated_pgp.search.search_id if duplicated_pgp

    pseudo_graph_pattern = PseudoGraphPattern.create(pgp:, query: @query, target:)
    search = create_search pseudo_graph_pattern
    SearchJob.perform_later search.search_id
    search.search_id
  end
end
