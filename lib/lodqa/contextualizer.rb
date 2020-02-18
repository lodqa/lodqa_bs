# frozen_string_literal: true

module Lodqa
  class Contextualizer
    attr_reader :anchored_pgp
    attr_reader :searches

    def initialize anchored_pgp, searches
      @anchored_pgp = anchored_pgp
      @searches = searches
    end
  end
end
