# frozen_string_literal: true

module SystemRDL
  module AST
    class Base < ::AST::Node
      def initialize(type, range, *children)
        super(type, children, { range: range })
      end

      attr_reader :range

      def replace_range(new_range)
        klass = self.class
        klass.new(new_range, *children)
      end
    end
  end
end
