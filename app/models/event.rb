# frozen_string_literal: true

# Events of searching the query.
# This instances are saved to the database and sent the data attribute to the LODQA WS.
class Event < ApplicationRecord
  belongs_to :query, primary_key: :query_id
  serialize :data

  class << self
    # Events that occurred while searching for queries.
    def occurred_for query
      where(query_id: query.query_id)
        .pluck :data
    end
  end

  def answer?
    event == 'answer'
  end

  def to_answer
    data[:answer].slice(:uri, :label)
  end
end
