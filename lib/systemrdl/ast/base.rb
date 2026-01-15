# frozen_string_literal: true

module SystemRDL
  module AST
    class Base < ::AST::Node
      def initialize(type, range, *children)
        @range = range
        super(type, children)
      end

      attr_reader :range
    end
  end
end
