# frozen_string_literal: true

module Lodqa
  class Contextualizer
    def initialize anchored_pgp, user_ids
      @anchored_pgp = anchored_pgp
      @user_ids = user_ids
    end

    attr_reader :user_ids
    attr_reader :anchored_pgp
  end
end
