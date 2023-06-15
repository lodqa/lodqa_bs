# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dialog do
  describe 'context' do
    it 'returns the natural language expressions' do
      dialog = described_class.create(user_id: 1)
      dialog.natural_language_expressions.create(query: 'Hello')

      expect(dialog.context).to eq dialog.natural_language_expressions
    end
  end

  describe 'with' do
    it 'returns the dialog with the specified user' do
      dialog = described_class.create(user_id: 1)
      expect(described_class.with(1)).to eq dialog
    end

    it 'creates a dialog with the specified user if not exists' do
      expect { described_class.with(1) }.to change(described_class, :count).by 1
    end
  end

  describe 'sentences_in' do
    it 'returns the sentences in specified depth' do
      dialog = described_class.create(user_id: 1)
      dialog.natural_language_expressions.create(query: 'Hello')
      dialog.natural_language_expressions.create(query: 'New')
      dialog.natural_language_expressions.create(query: 'World!')

      expect(dialog.sentences_in(2)).to eq %w[New World!]
    end
  end
end
