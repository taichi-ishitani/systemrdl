# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegDefinition < ComponentDefinition
      include AddressAllocation

      def validate(instance)
        check_regwidth(instance)
        check_accesswidth(instance)
        check_overlapping_fields(instance)
        check_fields_out_of_register(instance)
        check_fields_spanning_sub_word_boundary(instance)
        check_address(instance)
      end

      def revalidate(instance)
        check_accesswidth(instance)
        check_fields_spanning_sub_word_boundary(instance)
        check_address(instance)
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
        create_property(instance, :regwidth, [:longint], 32)
        create_property(instance, :accesswidth, [:longint], nil)
        create_property(instance, :errextbus, [:boolean], false)
        create_property(instance, :shared, [:boolean], false)
      end

      def apply_inst_values(instance, inst_values)
        apply_explicit_address(instance, inst_values)
      end

      def post_build(instance)
        apply_default_accesswidth(instance)
      end

      def apply_default_accesswidth(instance)
        property = instance.property(:accesswidth)
        return if property.value

        regwidth = instance.property_value(:regwidth)
        property.assign(regwidth)
      end

      def check_power_of_2(instance, name)
        value = instance.property_value(name)
        return if power_of_2?(value.value)

        message = "#{name} must be a power of 2: #{value}"
        raise_evaluation_error message, value.token_range
      end

      def power_of_2?(value)
        value >= 8 && value.nobits?(value - 1)
      end

      def check_regwidth(instance)
        check_power_of_2(instance, :regwidth)
      end

      def check_accesswidth(instance)
        check_power_of_2(instance, :accesswidth)

        regwidth = instance.property_value(:regwidth)
        accesswidth = instance.property_value(:accesswidth)
        return if accesswidth.value <= regwidth.value

        message = "accesswidth exceeds regwidth: accesswidth = #{accesswidth} regwidth = #{regwidth}"
        raise_evaluation_error message, accesswidth.token_range, regwidth.token_range
      end

      def check_overlapping_fields(instance)
        instance.instances.combination(2).each do |(field_a, field_b)|
          next unless overlapping_field_pair?(field_a, field_b)

          message = 'overlapping fields not allowed'
          raise_evaluation_error message, field_a.token_range, field_b.token_range
        end
      end

      def overlapping_field_pair?(field_a, field_b)
        range_a = (field_a.lsb.value..field_a.msb.value)
        range_b = (field_b.lsb.value..field_b.msb.value)
        return false unless range_a.include?(range_b.begin) || range_b.include?(range_a.begin)

        r_a, w_a = field_access(field_a)
        r_b, w_b = field_access(field_b)
        (r_a && r_b) || (w_a && w_b)
      end

      def field_access(instance)
        sw = instance.property_value(:sw).value
        readable = (sw in :rw | :r)
        writable = (sw in :rw | :w)
        [readable, writable]
      end

      def check_fields_out_of_register(instance)
        regwidth = instance.property_value(:regwidth).value
        instance.instances.each do |field|
          msb = field.msb.value
          lsb = field.lsb.value
          next if msb < regwidth

          message = "field out of register: bit position [#{msb}:#{lsb}] regwidth #{regwidth}"
          raise_evaluation_error message, field.token_range
        end
      end

      def check_fields_spanning_sub_word_boundary(instance)
        accesswidth = instance.property_value(:accesswidth).value
        instance.instances.each do |field|
          next unless field_with_side_effect?(field)

          msb = field.msb.value
          lsb = field.lsb.value
          next if (msb / accesswidth) == (lsb / accesswidth)

          message =
            'field spanning sub-word boundary not allowed: ' \
            "bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          raise_evaluation_error message, field.token_range
        end
      end

      def field_with_side_effect?(field)
        sw = field.property_value(:sw).value
        return true if sw in :rw | :w

        [:onread, :rclr, :rset]
          .any? { |prop| field.property_value(prop)&.value }
      end

      def inst_accesswidth(instance)
        instance.property_value(:accesswidth).value
      end
    end

    class RegInstance < Instance
      attr_accessor :address

      def layer
        :reg
      end

      def definable?(definition)
        definition.layer in :field
      end
    end
  end
end
