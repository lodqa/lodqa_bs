# frozen_string_literal: true

# Events of the query.
# This instances are sent to the LODQA WS and saved to the database.
class Event < ApplicationRecord
  belongs_to :query, primary_key: :query_id
  serialize :data

  class << self
    def answers query_id
      where(query_id: query_id, event: :answer)
        .pluck(:data)
        .pluck(:answer)
        .map { |a| a.slice(:uri, :label) }
        .uniq
        .as_json
    end

    def occurred query_id
      where(query_id: query_id)
        .pluck(:data)
    end
  end
end
