# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Root < ComponentDefinition
      def layer
        :root
      end

      def initialize(elements, token_range)
        super(Value.new(:root, nil, nil), nil, elements, nil, token_range)
        connect(nil, nil)
      end

      def evaluate(instance, finalize: true, **optargs)
        inst_args = InstArgs.new(:root, nil, nil, nil)
        root = instance || new_instance(nil, inst_args, nil)

        inherit(instance) if instance
        build_instance(root, inst_args, nil, **optargs)

        root.finalize if finalize
        root
      end

      private

      def instance_class
        RootInstance
      end

      def inherit(instance)
        definitions.merge!(instance.component_def.definitions)
      end
    end

    class RootInstance < Instance
      def definable?(_definition)
        true
      end
    end
  end
end
