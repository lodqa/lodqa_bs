# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contextualizer do
  describe 'contextualize' do
    it 'returns the contextualized natural language expression' do
      dialog = Dialog.create(user_id: 1)
      dialog.natural_language_expressions.create(query: 'Hello')

      contextualizer = described_class.new dialog
      cnle = contextualizer.contextualize

      expect(dialog.contextualized_natural_language_expressions.count).to eq 1
      expect(cnle.query).to eq 'Hello'
    end
  end
end
