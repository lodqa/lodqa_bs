# frozen_string_literal: true

# Term mapping
class TermMapping < ApplicationRecord
  serialize :mapping, coder: JSON

  belongs_to :pseudo_graph_pattern
end
