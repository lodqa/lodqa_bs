# frozen_string_literal: true

# Release db connection automatically after invoke the block
module DbConnection
  def self.using
    yield
  ensure
    ActiveRecord::Base.connection_pool.checkin ApplicationRecord.connection
  end
end
