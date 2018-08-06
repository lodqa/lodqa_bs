# frozen_string_literal: true

# Events of the query.
# This instances are sent to the LODQA WS and saved to the database.
class Event < ApplicationRecord
  serialize :data
end
