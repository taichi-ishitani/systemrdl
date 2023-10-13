# frozen_string_literal: true

module SystemRDL
  module AST
    class TrueLiteral < Base
      def initialize(value)
        super(:true_literal, value)
      end
    end

    class FalseLiteral < Base
      def initialize(value)
        super(:false_literal, value)
      end
    end

    class NumberLiteral < Base
      def initialize(number, base, width)
        assign_properties(number: number.str.to_i(base), width: width&.to_i)
        super(:number_literal, width, number)
      end

      attr_reader :number
      attr_reader :width
    end

    class StringLiteral < Base
      def initialize(string)
        assign_properties(string: unescape(string))
        super(:string_literal, string)
      end

      attr_reader :string

      private

      def unescape(string)
        string.str[1..-2].gsub('\"', '"')
      end
    end

    class AccesstypeLiteral < Base
      def initialize(accesstype)
        assign_properties(accesstype: accesstype.to_sym)
        super(:accesstype_literal, accesstype)
      end

      attr_reader :accesstype
    end

    class OnreadtypeLiteral < Base
      def initialize(onreadtype)
        assign_properties(onreadtype: onreadtype.to_sym)
        super(:onreadtype_literal, onreadtype)
      end

      attr_reader :onreadtype
    end

    class OnwritetypeLiteral < Base
      def initialize(onwritetype)
        assign_properties(onwritetype: onwritetype.to_sym)
        super(:onwritetype_literal, onwritetype)
      end

      attr_reader :onwritetype
    end

    class AddressingtypeLiteral < Base
      def initialize(addressingtype)
        assign_properties(addressingtype: addressingtype.to_sym)
        super(:addressingtype_literal, addressingtype)
      end

      attr_reader :addressingtype
    end

    class PrecedencetypeLiteral < Base
      def initialize(precedencetype)
        assign_properties(precedencetype: precedencetype.to_sym)
        super(:precedencetype_literal, precedencetype)
      end

      attr_reader :precedencetype
    end
  end
end
