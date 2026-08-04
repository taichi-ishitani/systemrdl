# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def layer
        :root
      end

      def initialize(elements, token_range)
        super(Value.new(:root, nil, nil, nil), elements, nil, token_range)
        connect(nil, nil)
      end

      def evaluate(instance, **optargs)
        inherit(instance) if instance&.root?
        root = create_instance(nil, :root, nil, nil, nil, nil, **optargs)
        root.finalize
        root
      end

      private

      def instance_class
        RootInstance
      end

      def inherit(instance)
        definitions.merge!(instance.definition.definitions)
      end
    end

    class RootInstance < Instance
      def definable?(_definition)
        true
      end
    end
  end
end
