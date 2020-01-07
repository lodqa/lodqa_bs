# frozen_string_literal: true

class TermMapping < ApplicationRecord
  serialize :mapping, JSON

  belongs_to :pseudo_graph_pattern
end
