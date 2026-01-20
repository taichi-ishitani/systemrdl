# frozen_string_literal: true

module SystemRDL
  module AST
    class Boolean < Base
      def initialize(range, token)
        super(:boolean, range, token)
      end
    end

    class String < Base
      def initialize(range, token)
        super(:string, range, token)
      end
    end

    class Number < Base
      def initialize(range, token)
        super(:number, range, token)
      end
    end

    class VerilogNumber < Base
      def initialize(range, token)
        super(:verilog_number, range, token)
      end
    end

    class AccessType < Base
      def initialize(range, token)
        super(:accesstype, range, token)
      end
    end

    class OnReadType < Base
      def initialize(range, token)
        super(:onreadtype, range, token)
      end
    end

    class OnWriteType < Base
      def initialize(range, token)
        super(:onwritetype, range, token)
      end
    end

    class AddressingType < Base
      def initialize(range, token)
        super(:addressingtype, range, token)
      end
    end

    class PrecedenceType < Base
      def initialize(range, token)
        super(:precedencetype, range, token)
      end
    end
  end
end
