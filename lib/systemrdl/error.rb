# frozen_string_literal: true

module SystemRDL
  class SystemRDLError < StandardError
    def initialize(message, position)
      super(message)
      @position = position
    end

    def to_s
      @position && "#{super} -- #{@position}" || super
    end
  end

  class ElaborationError < SystemRDLError
  end
end
