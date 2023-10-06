# config/initializers/sucker_punch_patches.rb
Rails.application.config.after_initialize do
  SuckerPunch::Job::ClassMethods.prepend(SuckerPunchJobExtensions)
  ActiveJob::QueueAdapters::SuckerPunchAdapter.prepend(SuckerPunchAdapterExtensions)
end
