# frozen_string_literal: true

module SystemRDL
  module AST
    class TrueLiteral < Base
      def initialize(position)
        super(:true_literal, position)
      end
    end

    class FalseLiteral < Base
      def initialize(position)
        super(:false_literal, position)
      end
    end

    class NumberLiteral < Base
      def initialize(position, number, width)
        assign_properties(number: number, width: width)
        super(:number_literal, position)
      end

      attr_reader :number
      attr_reader :width
    end

    class StringLiteral < Base
      def initialize(position, string)
        assign_properties(string: string)
        super(:string_literal, position)
      end

      attr_reader :string
    end
  end
end
