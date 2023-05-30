# frozen_string_literal: true

# Pseudo Graph Pattern
# A PGP contains nodes and relations.
# Typically, the nodes correspond to the basic noun phrases (BNPs) in the NL query,
# and the relations to the dependency paths between the BNPs as expressed in the NL query.
# Additionally, a PGP specifies which node is the focus of the query,
# i.e. what the user wants to get as the answer of the query, e.g., 'genes'
# in the above example query.
class PseudoGraphPattern < ApplicationRecord
  serialize :pgp, JSON

  has_many :searches, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :term_mappings, dependent: :destroy
  has_many :all_answers, -> { where(event: 'answer') },
           class_name: :Event

  scope :alive?, -> { where aborted_at: nil }

  class << self
    def equals_in pgp, other
      PseudoGraphPattern.alive?
                        .where(pgp:)
                        .where(read_timeout: other.read_timeout)
                        .where(sparql_limit: other.sparql_limit)
                        .where(answer_limit: other.answer_limit)
                        .where(target: other.target)
                        .where(private: false)
                        .order(created_at: :desc)
                        .first
    end

    # Abort unfinished searches
    def abort_unfinished_searches!
      transaction do
        where(finished_at: nil)
          .alive?
          .each(&:abort!)
          .any?
      end
    end

    def prune
      PseudoGraphPattern.where(id: Search.expired?.select(:pseudo_graph_pattern_id)).destroy_all
    end
  end

  # Abort to search and save the abort time.
  def abort!
    update aborted_at: Time.now.utc
  end

  # Return state of search to use in the index page of queries.
  def state
    return :aborted if aborted_at.present?
    return :finished if finished_at.present?
    return :running if started_at.present?

    :queued
  end

  # Return answers of the search.
  def answers
    all_answers.map(&:to_answer).uniq
  end

  # Return elapsed time of the finished search.
  def elapsed_time
    return nil if started_at.blank? || aborted_at.present?

    (finished_at.presence || Time.zone.now) - started_at
  end

  def data_for_start_event
    {
      read_timeout:,
      sparql_limit:,
      answer_limit:,
      cache: private ? :no : :yes,
      start_at: started_at
    }
  end

  def data_for_search_detail
    {
      read_timeout:,
      sparql_limit:,
      answer_limit:,
      target:,
      private:,
      state:,
      created_at: to_strftime(created_at),
      started_at: to_strftime(started_at),
      finished_at: to_strftime(finished_at),
      elapsed_time: elapsed_time&.to_f&.ceil(1),
      number_with_precision: answers.size
    }
  end

  def data_for_finish_event
    {
      finish_at: finished_at,
      elapsed_time:,
      answers: answers.as_json
    }
  end

  private

  def to_strftime date
    return nil unless date

    date.in_time_zone.strftime('%m/%d %H:%M')
  end
end
