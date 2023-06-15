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
    "#{Rails.application.config.contextualizer[:instruction]} #{sentences}"
  end

  private

  def sentences
    depth = Rails.application.config.contextualizer[:dialog_depth]

    @dialog.sentences_in(depth)
           .map { _1.end_with?('.', '?') ? _1 : "#{_1}." }
           .join(' ')
  end
end
