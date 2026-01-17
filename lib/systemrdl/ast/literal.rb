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

    class Number < Literal
      def initialize(token)
        super(:number, token)
      end
    end

    class VerilogNumber < Literal
      def initialize(token)
        super(:verilog_number, token)
      end
    end

    class AccessType < Literal
      def initialize(token)
        super(:accesstype, token)
      end
    end

    class OnReadType < Literal
      def initialize(token)
        super(:onreadtype, token)
      end
    end

    class OnWriteType < Literal
      def initialize(token)
        super(:onwritetype, token)
      end
    end

    class AddressingType < Literal
      def initialize(token)
        super(:addressingtype, token)
      end
    end

    class PrecedenceType < Literal
      def initialize(token)
        super(:precedencetype, token)
      end
    end
  end
end
