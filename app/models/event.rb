# frozen_string_literal: true

# Events of searching the query.
# This instances are saved to the database and sent the data attribute to the LODQA WS.
class Event < ApplicationRecord
  belongs_to :query, primary_key: :query_id
  serialize :data

  class << self
    # Return answers of the query
    def answers_of query
      where(query_id: query.query_id, event: :answer)
        .pluck(:data)
        .pluck(:answer)
        .map { |a| a.slice(:uri, :label) }
        .uniq
    end

    def occurred query_id
      where(query_id: query_id)
        .pluck(:data)
    end
  end
end
