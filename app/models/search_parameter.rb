# frozen_string_literal: true

require 'lodqa/sources'

# Parameter class to validate parameters independently from Search and PseudoGraphPattern
class SearchParameter
  include ActiveModel::Model

  attr_accessor :query, \
                :read_timeout, :sparql_limit, :answer_limit, :target, :private, \
                :callback_url

  validates :read_timeout,
            :sparql_limit,
            :answer_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def initialize params
    self.query = params[:query]
    self.read_timeout = params[:read_timeout] || 5
    self.sparql_limit = params[:sparql_limit] || 100
    self.answer_limit = params[:answer_limit] || 10
    self.target = params[:target] || acquire_targets
    self.private = params[:cache] == 'no'
    self.callback_url = params[:callback_url]
  end

  private

  def acquire_targets
    Lodqa::Sources.all_datasets.map { |d| d[:name] }.join(', ')
  end
end
