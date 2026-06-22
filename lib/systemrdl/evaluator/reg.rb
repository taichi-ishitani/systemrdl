# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegDefinition < ComponentDefinition
      def validate(instance)
        check_overlapping_fields(instance)
      end

      def layer
        :reg
      end

      private

      def instance_class
        RegInstance
      end

      def init_properties(instance)
        super

        #
        # Table 23—Register properties
        #
        create_property(instance, :regwidth, [:longint], nil)
        create_property(instance, :accesswidth, [:longint], nil)
        create_property(instance, :errextbus, [:boolean], false)
        create_property(instance, :shared, [:boolean], false)
      end

      def check_overlapping_fields(instance)
        instance.instances.combination(2).each do |(field_a, field_b)|
          check_overlapping_field_pair(field_a, field_b)
        end
      end

      def check_overlapping_field_pair(field_a, field_b)
        range_a = (field_a.lsb.value..field_a.msb.value)
        range_b = (field_b.lsb.value..field_b.msb.value)
        return unless range_a.include?(range_b.begin) || range_b.include?(range_a.begin)

        r_a, w_a = field_access(field_a)
        r_b, w_b = field_access(field_b)
        return unless (r_a && r_b) || (w_a && w_b)

        message = 'overlapping fields not allowed'
        raise_evaluation_error message, field_a.token_range, field_b.token_range
      end

      def field_access(instance)
        sw = instance.property_value(:sw).value
        readable = (sw in :rw | :r)
        writable = (sw in :rw | :w)
        [readable, writable]
      end
    end

    class RegInstance < Instance
      def layer
        :reg
      end

      def definable?(definition)
        definition.layer in :field
      end
    end
  end
end
