OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY") { nil }
end

Rails.application.configure do
  config.contextualizer = {
    instruction: "Make the following sentences into one sentence:",
    dialog_depth: 2,
  }
end