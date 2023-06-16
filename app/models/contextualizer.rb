# frozen_string_literal: true

# Contextualize natural language expressions in dialog.
class Contextualizer
  def initialize dialog
    @dialog = dialog
  end

  def contextualize
    # create a prompt from context
    # Call OpenAI API
    query = if !@dialog.one_sentence? && ENV.fetch('OPENAI_API_KEY', nil)
              client = OpenAI::Client.new
              response = client.completions(parameters: { model: 'text-davinci-001',
                                                          prompt:,
                                                          temperature: 0 })
              response['choices'].first['text'].strip
            else
              @dialog.context.last.query
            end

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
