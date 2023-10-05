# frozen_string_literal: true

require 'lodqa/sources'
require 'json'

# Parameter class to validate parameters independently from Search and PseudoGraphPattern
class SearchParameter
  include ActiveModel::Model

  attr_accessor :query, :pgp, :mappings, \
                :read_timeout, :sparql_limit, :answer_limit, :target, :user_id, \
                :private, :callback_url

  validates :read_timeout,
            :sparql_limit,
            :answer_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def initialize params
    self.query = params[:query]
    self.pgp = convert_param_to_json(params[:pgp])
    self.mappings = convert_param_to_json(params[:mappings])
    self.read_timeout = params[:read_timeout] || 5
    self.sparql_limit = params[:sparql_limit] || 100
    self.answer_limit = params[:answer_limit] || 10
    self.target = params[:target] || acquire_targets
    self.user_id = params[:user_id]
    self.private = params[:cache] == 'no'
    self.callback_url = params[:callback_url]
  end

  def simple_mode?
    query.present?
  end

  private

  def convert_param_to_json param
    param.blank? ? nil : JSON.parse(param)
  end

  def acquire_targets
    Lodqa::Sources.targets.join(', ')
  end
end
