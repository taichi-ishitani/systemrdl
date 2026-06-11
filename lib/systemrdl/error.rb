# frozen_string_literal: true

module SystemRDL
  class Error < StandardError
    def initialize(message)
      super
      @error_message = message
    end

    attr_reader :error_message
  end

  class ParseError < Error
    def initialize(message, position)
      super(message)
      @position = position
    end

    attr_reader :position

    def to_s
      (@position && "#{super} -- #{@position}") || super
    end
  end

  module RaiseParseError
    private

    def raise_parse_error(message, position)
      raise ParseError.new(message, position)
    end
  end

  class EvaluationError < Error
    def initialize(message, *token_ranges)
      super(message)
      @token_ranges = token_ranges.compact
    end

    attr_reader :token_ranges

    def to_s
      position = token_ranges.first&.head&.position
      (position && "#{super} -- #{position}") || super
    end
  end

  module RaiseEvaluationError
    private

    def raise_evaluation_error(message, *token_ranges)
      raise EvaluationError.new(message, *token_ranges)
    end
  end
end
