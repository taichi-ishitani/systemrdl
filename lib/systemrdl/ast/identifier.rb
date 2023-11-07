# frozen_string_literal: true

module SystemRDL
  module AST
    class ID < Base
      def initialize(id)
        assign_properties(id: id.to_sym)
        super(:id, id)
      end

      attr_reader :id

      def to_s
        id.to_s
      end
    end

    class ThisKeyword < Base
      def initialize(id)
        super(:this_keyword, id)
      end
    end
  end
end
