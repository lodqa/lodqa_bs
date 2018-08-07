# frozen_string_literal: true

# Events of the query.
# This instances are sent to the LODQA WS and saved to the database.
class Event < ApplicationRecord
  serialize :data

  def self.answers query_id
    where(query_id: query_id, event: :answer)
      .pluck(:data)
      .pluck(:answer)
      .map { |a| a.slice(:uri, :label) }
      .uniq
      .as_json
  end
end
