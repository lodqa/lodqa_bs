# frozen_string_literal: true

# Job characteristics common to applications.
class ApplicationJob < ActiveJob::Base
  include SuckerPunch::Job
end
