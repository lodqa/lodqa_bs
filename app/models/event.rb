# frozen_string_literal: true

# Events of searching the query.
# This instances are saved to the database and sent the data attribute to the LODQA WS.
class Event < ApplicationRecord
  belongs_to :search, primary_key: :search_id
  serialize :data, JSON

  class << self
    # Events that occurred while searching for queries.
    # When the number of events is large,
    # the reading time from the DB is about several seconds to about 10 seconds.
    # In order to send the first event fast, read events from the DB piece by piece.
    def occurred_for search, offset_size
      Enumerator.new do |enum|
        i = 0
        loop do
          events = DbConnection.using do
            where(search_id: search.search_id)
              .order(:id)
              .limit(offset_size)
              .offset(i)
              .pluck :data
          end
          break if events.empty?

          enum.yield events
          i += offset_size
        end
      end
    end
  end

  def to_answer
    data['answer'].slice('uri', 'label')
  end
end
