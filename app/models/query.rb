# frozen_string_literal: true

# The query accepted.
class Query < ApplicationRecord
  has_many :events, primary_key: :query_id

  class << self
    # Start to search the query and save the start time.
    def start! query_id
      query = find_by query_id: query_id
      query.started_at = Time.now.utc
      query.save!
      query
    end

    # Abort unfinished queries
    def abort_unfinished_queries
      transaction do
        done = Query.where(finished_at: nil)
                    .where(aborted_at: nil)
                    .each do |q|
          q.aborted_at = Time.now.utc
          q.save!
        end
        p 'Abort unfinished query' unless done.empty?
      end
    end
  end

  # Invoke received block if the query finished.
  def finished?
    transaction do
      yield unless reload.finished_at.present?
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

  # Return answers of the query.
  def answers
    events.select(&:answer?).map(&:to_answer).uniq
  end

  # Return elapsed time of the finished query.
  def elapsed_time
    return nil unless started_at.present? && finished_at.present?

    finished_at - started_at
  end
end
