# frozen_string_literal: true

# Term mapping
class TermMapping < ApplicationRecord
  serialize :mapping, JSON

  belongs_to :pseudo_graph_pattern
end
