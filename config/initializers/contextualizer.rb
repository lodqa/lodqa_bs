OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
end

Rails.application.configure do
  config.contextulizer = {
    instruction: "Make the following sentences into one sentence:",
    dialog_depth: 2,
  }
end