# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def initialize(elements, token_range)
        super(Value.new(:root, nil, nil, nil), elements, nil, token_range)
        connect(nil, nil)
      end

      def evaluate(_instance, **optargs)
        root = create_instance(nil, :root, nil, nil, nil, **optargs)
        root.finalize
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

      def definable?(_definition)
        true
      end
    end
  end
end
