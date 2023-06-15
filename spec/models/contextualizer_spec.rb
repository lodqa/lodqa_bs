# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contextualizer do
  let(:dialog) { Dialog.create(user_id: 1) }

  describe 'contextualize' do
    it 'returns the contextualized natural language expression' do
      dialog.natural_language_expressions.create(query: 'Hello')

      contextualizer = described_class.new dialog
      cnle = contextualizer.contextualize

      expect(dialog.contextualized_natural_language_expressions.count).to eq 1
      expect(cnle.query).to eq 'Hello'
    end
  end

  describe 'prompt' do
    it 'returns instruction and context' do
      dialog.natural_language_expressions.create(query: 'Hello.')

      contextualizer = described_class.new dialog
      prompt = contextualizer.prompt

      expect(prompt).to eq 'Make the following sentences into one sentence: Hello.'
    end

    context 'when query has no period or question mark' do
      it 'returns sentence with period' do
        dialog.natural_language_expressions.create(query: 'Hello')

        contextualizer = described_class.new dialog
        prompt = contextualizer.prompt

        expect(prompt).to eq 'Make the following sentences into one sentence: Hello.'
      end
    end

    context 'when query has question mark' do
      it 'returns sentence with question mark' do
        dialog.natural_language_expressions.create(query: 'Hello?')

        contextualizer = described_class.new dialog
        prompt = contextualizer.prompt

        expect(prompt).to eq 'Make the following sentences into one sentence: Hello?'
      end
    end
  end
end
