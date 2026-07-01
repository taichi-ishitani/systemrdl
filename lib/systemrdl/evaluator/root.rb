# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def initialize(elements, token_range)
        super(Value.new(:root, nil), elements, nil, token_range)
        connect(self, self)
      end

      def evaluate(_instance, **optargs)
        root = create_instance(nil, :root, nil, nil, nil, nil, **optargs)
        @elements.each do |element|
          element.evaluate(root, **optargs)
        end
        root
      end

      private

      def instance_class
        RootInstance
      end
    end

    class RootInstance < Instance
      def layer
        :root
      end
    end
  end
end
