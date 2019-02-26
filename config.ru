# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
require_relative 'config/lodqa_bs_data_cleaner'

run Rails.application
