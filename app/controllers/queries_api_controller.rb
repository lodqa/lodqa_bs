# frozen_string_literal: true

# A controller to register a new query.
class QueriesApiController < ActionController::API
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  # Show information about a registered query.
  def show
    render json: Query.find_by(query_id: params[:id]), except: :id
  end

  # Register a new query and run a new job to search the query.
  def create
    query_id = register Query.new query_attributes
    render json: to_hash(query_id)
  end

  private

  # Register a statement.
  # return query_id if same statement exists.
  def register query
    cache = Query.equals_in query

    return cache.query_id if cache

    job = SearchJob.perform_later query.start_search_callback_url, query.finish_search_callback_url
    query.query_id = job.job_id
    query.save!
    query.query_id
  end

  def query_attributes
    params.require(%i[
                     query
                     start_search_callback_url
                     finish_search_callback_url
                   ])
    params.tap { |p| p[:statement] = p[:query] }
          .permit(%i[
                    statement
                    start_search_callback_url
                    finish_search_callback_url
                    read_timeout
                    sparql_limit
                    answer_limit
                  ])
  end

  def to_hash query_id
    {
      query_id: query_id,
      query_url: "#{ENV['LODQA']}/answer?query_id=#{query_id}"
    }
  end
end
