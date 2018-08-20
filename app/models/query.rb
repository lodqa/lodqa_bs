# frozen_string_literal: true

# The query accepted.
class Query < ApplicationRecord
  def self.start! query_id
    query = find_by query_id: query_id
    query.started_at = Time.now.utc
    query.save!
    query
  end

  def finish!
    self.finished_at = Time.now.utc
    save!
    self
  end

  def elapsed_time
    raise RangeError, 'Query does not finish' unless started_at.present? && finished_at.present?

    finished_at - started_at
  end
end
