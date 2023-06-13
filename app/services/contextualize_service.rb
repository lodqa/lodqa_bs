# frozen_string_literal: true

# Contextualize natural language expressions in dialog.
module ContextualizeService
  class << self
    def contextualize dialog
      context = dialog.context

      # create a prompt from context
      # Call OpenAI API
      # Now, use dummy value.
      query = context.last.query

      dialog.contextualized_natural_language_expressions.create query:
    end
  end
end
