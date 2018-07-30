# frozen_string_literal: true

require 'sparql_client/endpoint_temporary_error'

module SparqlClient
  class EndpointTimeoutError < EndpointTemporaryError; end
end
