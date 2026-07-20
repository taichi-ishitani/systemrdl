# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class AddrMapDefinition < ComponentDefinition
      include AddressAllocation

      def evaluate(instance, **optargs)
        if instance.root?
          create_instance(instance, @id, nil, nil, nil, **optargs)
        else
          super
        end
      end

      def validate(instance)
        check_alignment(instance)
        check_endianness_exclusivity(instance)
        check_rsvdset_exclusivity(instance)
        check_bit_ordering_exclusivity(instance)
      end

      def finalize(instance)
        allocate_addresses(instance)
        check_overlapping_regs(instance)
      end

      def layer
        :addrmap
      end

      private

      def instance_class
        AddrMapInstance
      end

      def check_alignment(instance)
        check_power_of_2(instance, :alignment, 1)
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
      def layer
        :addrmap
      end

      def definable?(definition)
        definition.layer in :addrmap | :regfile | :reg
      end
    end
  end
end
