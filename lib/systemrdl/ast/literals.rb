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

    class AccesstypeLiteral < Base
      def initialize(position, accesstype)
        assign_properties(accesstype: accesstype)
        super(:accesstype_literal, position)
      end

      attr_reader :accesstype
    end

    class OnreadtypeLiteral < Base
      def initialize(position, onreadtype)
        assign_properties(onreadtype: onreadtype)
        super(:onreadtype_literal, position)
      end

      attr_reader :onreadtype
    end

    class OnwritetypeLiteral < Base
      def initialize(position, onwritetype)
        assign_properties(onwritetype: onwritetype)
        super(:onwritetype_literal, position)
      end

      attr_reader :onwritetype
    end

    class AddressingtypeLiteral < Base
      def initialize(position, addressingtype)
        assign_properties(addressingtype: addressingtype)
        super(:addressingtype_literal, position)
      end

      attr_reader :addressingtype
    end

    class PrecedencetypeLiteral < Base
      def initialize(position, precedencetype)
        assign_properties(precedencetype: precedencetype)
        super(:precedencetype_literal, position)
      end

      attr_reader :precedencetype
    end
  end
end
