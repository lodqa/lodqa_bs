# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contextualizer do
  let(:dialog) { Dialog.create(user_id: 1) }
  let(:contextualizer) do
    dialog.natural_language_expressions.create(query: 'Hello.')
    described_class.new dialog
  end

  describe 'contextualize' do
    before do
      stub_request(:post, 'https://api.openai.com/v1/completions')
        .with(
          body: {
            'model' => 'text-davinci-001',
            'prompt' => 'Make the following sentences into one sentence: Hello.',
            'temperature' => 0
          }.to_json

        )
        .to_return(status: 200,
                   body: { 'choices' =>
                                        [{
                                          'text' => "\n\nHello."
                                        }] }.to_json,
                   headers: {})
    end

    it 'returns the contextualized natural language expression' do
      cnle = contextualizer.contextualize

      expect(dialog.contextualized_natural_language_expressions.count).to eq 1
      expect(cnle.query).to eq 'Hello.'
    end
  end

  describe 'prompt' do
    it 'returns instruction and context' do
      prompt = contextualizer.prompt

      expect(prompt).to eq 'Make the following sentences into one sentence: Hello.'
    end

    context 'when query has no period or question mark' do
      let(:contextualizer) do
        dialog.natural_language_expressions.create(query: 'Hello')
        described_class.new dialog
      end

      it 'returns sentence with period' do
        prompt = contextualizer.prompt

        expect(prompt).to eq 'Make the following sentences into one sentence: Hello.'
      end
    end

    context 'when query has question mark' do
      let(:contextualizer) do
        dialog.natural_language_expressions.create(query: 'Hello?')
        described_class.new dialog
      end

      it 'returns sentence with question mark' do
        prompt = contextualizer.prompt

        expect(prompt).to eq 'Make the following sentences into one sentence: Hello?'
      end
    end

    context 'when dialog is longer than dialog depth' do
      let(:contextualizer) do
        dialog.natural_language_expressions.create(query: 'Hello.')
        dialog.natural_language_expressions.create(query: 'How are you?')
        dialog.natural_language_expressions.create(query: 'I am fine.')
        described_class.new dialog
      end

      it 'returns only the last dialog depth sentences' do
        prompt = contextualizer.prompt

        expect(prompt).to eq 'Make the following sentences into one sentence: How are you? I am fine.'
      end
    end
  end
end
