# frozen_string_literal: true

module SystemRDL
  module AST
    class Base < ::AST::Node
      def initialize(type, position, children = [], properties = {})
        assign_properties(position: position)
        super(type, children, properties)
      end

      attr_reader :position
    end
  end
end
