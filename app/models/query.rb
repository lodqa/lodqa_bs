# frozen_string_literal: true

# The query accepted.
class Query < ApplicationRecord
  class << self
    def start! query_id
      query = find_by query_id: query_id
      query.started_at = Time.now.utc
      query.save!
      query
    end

    def finished? query_id
      Query.transaction do
        yield unless Query.find_by(query_id: query_id).finished_at.present?
      end
    end
  end

  def finish!
    transaction do
      self.finished_at = Time.now.utc
      save!

      yield

      self
    end
  end

  def elapsed_time
    return nil unless started_at.present? && finished_at.present?

    finished_at - started_at
  end
end
