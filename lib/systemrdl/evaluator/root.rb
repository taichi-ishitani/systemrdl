# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def initialize(elements, token_range)
        super(Value.new(:root, nil), elements, nil, token_range)
        connect(self, self)
      end

      def evaluate(instance, **optargs)
        @elements.each do |element|
          element.evaluate(instance, **optargs)
        end
      end
    end

    class RootInstance < Instance
      def initialize
        super(nil, :root)
      end
    end
  end
end
