# frozen_string_literal: true

module Lodqa
  class Contextualizer
    def initialize anchored_pgp, dialogs
      @anchored_pgp = anchored_pgp
      @dialogs = dialogs
    end

    def anchored_pgp
      @anchored_pgp
    end
  end
end
