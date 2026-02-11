# frozen_string_literal: true

module SystemRDL
  class Error < StandardError
    def initialize(message, position)
      super(message)
      @error_message = message
      @position = position
    end

    attr_reader :error_message
    attr_reader :position

    def to_s
      (position && "#{super} -- #{position}") || super
    end
  end

  class ParseError < Error
  end

  module RaiseParseError
    private

    def raise_parse_error(message, position)
      raise ParseError.new(message, position)
    end
  end

  class EvaluationError < Error
  end

  module RaiseEvaluationError
    private

    def raise_evaluation_error(message, position)
      raise EvaluationError.new(message, position)
    end
  end
end
