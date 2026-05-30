# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def initialize(elements, range)
        super(:root, elements, nil, range)
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
