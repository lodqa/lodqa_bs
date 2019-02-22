# frozen_string_literal: true

# Events of searching the query.
# This instances are saved to the database and sent the data attribute to the LODQA WS.
class Event < ApplicationRecord
  belongs_to :search, primary_key: :search_id
  serialize :data, JSON

  class << self
    def reader_by offset_size, conditions
      Enumerator.new do |enum|
        i = 0
        loop do
          events = DbConnection.using do
            where(conditions)
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
