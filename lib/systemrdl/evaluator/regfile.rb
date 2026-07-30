# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegFileDefinition < ComponentDefinition
      include ContainerComponent

      def validate(instance)
        check_structural_component_instances(instance)
      end

      def layer
        :regfile
      end

      private

      def instance_class
        RegFileInstance
      end
    end

    class RegFileInstance < Instance
      def layer
        :regfile
      end

      def definable?(definition)
        definition.layer in :regfile | :reg | :field
      end

      def instantiable?(definition)
        definition.layer in :regfile | :reg
      end
    end
  end
end
