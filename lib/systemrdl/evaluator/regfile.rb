# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegFileDefinition < ComponentDefinition
      include BlockComponent

      def validate(instance)
        check_structural_component_instances(instance)
        check_alignment_property(instance)
      end

      def finalize(instance)
        allocate_addresses(instance)
        check_address_operations(instance)
        check_overlapping_address_ranges(instance)
      end

      def layer
        :regfile
      end

      private

      def instance_class
        RegFileInstance
      end

      def apply_inst_values(instance, inst_values)
        apply_address_operations(instance, inst_values)
        check_range(inst_values)
      end
    end

    class RegFileInstance < Instance
      include BlockInstance

      def definable?(definition)
        definition.layer in :regfile | :reg | :field
      end

      def instantiable?(definition)
        definition.layer in :regfile | :reg
      end
    end
  end
end
