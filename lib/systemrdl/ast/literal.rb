# frozen_string_literal: true

module SystemRDL
  module AST
    class Literal < Base
      def initialize(kind, token)
        range = TokenRange.new(token)
        super(kind, range, token)
      end
    end

    class Boolean < Literal
      def initialize(token)
        super(:boolean, token)
      end
    end

    class String < Literal
      def initialize(token)
        super(:string, token)
      end
    end
  end
end
