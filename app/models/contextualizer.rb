# frozen_string_literal: true

# Contextualize natural language expressions in dialog.
class Contextualizer
  def initialize dialog
    @dialog = dialog
  end

  def contextualize
    context = @dialog.context

    # create a prompt from context
    # Call OpenAI API
    # Now, use dummy value.
    query = context.last.query

    @dialog.contextualized_natural_language_expressions.create query:
  end

  def prompt
    instruction = Rails.application.config.contextualizer[:instruction]
    sentences = @dialog.sentences_in Rails.application.config.contextualizer[:dialog_depth]
    "#{instruction} #{sentences.join(' ')}"
  end
end
