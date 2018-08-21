# frozen_string_literal: true

# The query accepted.
class Query < ApplicationRecord
  class << self
    # Start to search the query and save the start time.
    def start! query_id
      query = find_by query_id: query_id
      query.started_at = Time.now.utc
      query.save!
      query
    end

    # Invoke received block if the query finished.
    def finished? query_id
      Query.transaction do
        yield unless Query.find_by(query_id: query_id).finished_at.present?
      end
    end
  end

  # Finish to search the query and save the finish time.
  # And invoke received block. For example remove subscriptions of the query.
  def finish!
    transaction do
      self.finished_at = Time.now.utc
      save!

      yield

      self
    end
  end

  # Return elapsed time of the finished query.
  def elapsed_time
    return nil unless started_at.present? && finished_at.present?

    finished_at - started_at
  end
end
