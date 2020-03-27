# frozen_string_literal: true

require 'json'

# Parameter class to keep parameters independently from SparqlsCount
class SparqlsParameter
  attr_accessor :pgp, :mappings, :endpoint_url, :endpoint_options, \
                :graph_uri, :graph_finder_options

  def initialize params
    self.pgp = convert_param_to_json(params[:pgp])
    self.mappings = convert_param_to_json(params[:mappings])
    self.endpoint_url = params[:endpoint_url]
    self.endpoint_options = convert_param_to_json(params[:endpoint_options])
    self.graph_uri = params[:graph_uri]
    self.graph_finder_options = convert_param_to_json(params[:graph_finder_options])
  end

  private

  def convert_param_to_json param
    param.blank? ? nil : JSON.parse(param, symbolize_names: true)
  end
end
