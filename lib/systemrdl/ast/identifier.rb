# frozen_string_literal: true

module SystemRDL
  module AST
    class ID < Base
      def initialize(position, id)
        assign_properties(id: id)
        super(:id, position)
      end

      attr_reader :id
    end

    class ThisKeyword < Base
      def initialize(position)
        super(:this_keyword, position)
      end
    end
  end
end
