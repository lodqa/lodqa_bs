# frozen_string_literal: true

# Events of searching the query.
# This instances are saved to the database and sent the data attribute to the LODQA WS.
class Event < ApplicationRecord
  belongs_to :search, primary_key: :search_id
  serialize :data

  class << self
    # Events that occurred while searching for queries.
    def occurred_for search
      where(search_id: search.search_id)
        .pluck :data
    end
  end

  def to_answer
    data[:answer].slice(:uri, :label)
  end
end
