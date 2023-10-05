# frozen_string_literal: true

# Search for Chat GPT Plugin API
class ChatGptSearch
  include CanStartSearch

  def initialize query
    @query = query
    @targets = Lodqa::Sources.targets
  end

  # This is simple prototype search.
  # Only do start search job.
  # Do not do callback.
  # Do not do duplicate check.
  # Do not do contextualization.
  def run
    pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern @query
    pseudo_graph_pattern = PseudoGraphPattern.create(pgp:, query: @query, target:)
    search = create_search pseudo_graph_pattern
    SearchJob.perform_later search.search_id
    search.search_id
  end
end
