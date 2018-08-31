# frozen_string_literal: true

# The query accepted.
class Query < ApplicationRecord
  has_many :events, primary_key: :query_id
  before_create { self.queued_at = Time.now }

  class << self
    # Check does a same statement exists?
    def equals_in other
      Query.where(queued_at: Date.today.all_day)
           .where(aborted_at: nil)
           .where(statement: other.statement)
           .where(start_search_callback_url: other.start_search_callback_url)
           .where(finish_search_callback_url: other.finish_search_callback_url)
           .where(read_timeout: other.read_timeout)
           .where(sparql_limit: other.sparql_limit)
           .where(answer_limit: other.answer_limit)
           .order(queued_at: :desc)
           .first
    end

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
  def not_finished?
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
    return nil if !started_at.present? || aborted_at.present?

    (finished_at.present? ? finished_at : Time.now) - started_at
  end

  # Return state of query to use in the index page of queries.
  def state
    return :aborted if aborted_at.present?
    return :finished if finished_at.present?
    return :running if started_at.present?
    :queued
  end
end
