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
end
