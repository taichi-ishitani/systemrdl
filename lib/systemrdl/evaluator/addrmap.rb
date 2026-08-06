# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class AddrMapDefinition < ComponentDefinition
      include BlockComponent

      def evaluate(instance, **optargs)
        if instance.root?
          create_instance(instance, InstArgs.new(@id, nil, nil), nil, nil, **optargs)
        else
          super
        end
      end

      def validate(instance)
        check_structural_component_instances(instance)
        check_alignment_property(instance)
        check_endianness_exclusivity(instance)
        check_rsvdset_exclusivity(instance)
        check_bit_ordering_exclusivity(instance)
      end

      def finalize(instance)
        allocate_addresses(instance)
        check_address_operations(instance)
        check_overlapping_address_ranges(instance)
      end

      def layer
        :addrmap
      end

      def support_inst_type?(inst_type)
        inst_type.nil?
      end

      private

      def instance_class
        AddrMapInstance
      end

      def apply_inst_values(instance, inst_values)
        return if instance.parent.root?

        apply_address_operations(instance, inst_values)
        check_range(inst_values)
      end

      def check_endianness_exclusivity(instance)
        check_property_exclusivity(instance, [:bigendian, :littleendian])
      end

      def check_rsvdset_exclusivity(instance)
        check_property_exclusivity(instance, [:rsvdset, :rsvdsetX])
      end

      def check_bit_ordering_exclusivity(instance)
        check_property_exclusivity(instance, [:msb0, :lsb0])
      end
    end

    class AddrMapInstance < Instance
      include BlockInstance

      def definable?(definition)
        definition.layer in :addrmap | :regfile | :mem | :reg | :field
      end

      def instantiable?(definition)
        definition.layer in :addrmap | :regfile | :mem | :reg
      end
    end
  end
end
