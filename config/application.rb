require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Tokyo'
    config.active_job.queue_adapter = :sucker_punch

    config.lodqa_bs = config_for :lodqa_bs

    config.eager_load_paths << Rails.root.join('lib')

    # configures CORS for Chat GPT Plugin
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'  # allow all origins
        resource '/.well-known/ai-plugin.json', headers: :any, methods: :options
        resource '/openapi.yaml', headers: :any, methods: :options
        resource '/chat_gpt_plugin', headers: :any, methods: :post
      end
    end
  end
end
