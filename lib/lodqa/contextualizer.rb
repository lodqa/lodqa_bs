# frozen_string_literal: true

module Lodqa
  class Contextualizer
    def initialize anchored_pgp, user_ids
      @anchored_pgp = anchored_pgp
      @user_ids = user_ids
    end

    def user_ids
      @user_ids
    end

    def anchored_pgp
      @anchored_pgp
    end
  end
end
