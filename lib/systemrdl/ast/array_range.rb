# frozen_string_literal: true

module SystemRDL
  module AST
    class Array < Base
      def initialize(range, expression)
        super(:array, range, expression)
      end
    end
  end
end
