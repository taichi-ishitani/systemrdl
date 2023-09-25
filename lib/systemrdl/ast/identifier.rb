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
  end
end
