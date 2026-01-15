# frozen_string_literal: true

module SystemRDL
  module AST
    class Boolean < Base
      def initialize(token)
        range = TokenRange.new(token)
        super(:boolean, range, token)
      end
    end
  end
end
