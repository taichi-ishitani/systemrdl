# frozen_string_literal: true

module SystemRDL
  module Parser
    module RaiseParseError
      private

      def raise_parse_error(message, position)
        raise ParseError.new(message, position)
      end
    end
  end
end
