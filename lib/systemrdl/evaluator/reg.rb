# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegDefinition < ComponentDefinition
      include AddressOperation
      include InstTypeAwareComponent
      include ArrayComponent
      include ContainerComponent

      def validate(instance)
        check_structural_component_instances(instance)
        check_regwidth(instance)
        check_accesswidth(instance)
        check_fields_out_of_register(instance)
        check_fields_spanning_sub_word_boundary(instance)
        check_address_operations(instance)
      end

      def revalidate(instance)
        check_accesswidth(instance)
        check_fields_spanning_sub_word_boundary(instance)
        check_address_operations(instance)
      end

      def finalize(instance)
        check_field_ordering(instance)
        allocate_bits(instance)
        check_overlapping_fields(instance)
        check_fields_out_of_register(instance)
        check_fields_spanning_sub_word_boundary(instance)
      end

      def layer
        :reg
      end

      def support_inst_type?(_inst_type)
        true
      end

      private

      def instance_class
        RegInstance
      end

      def apply_inst_values(instance, inst_values)
        apply_address_operations(instance, inst_values)
        check_range(inst_values)
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

      def check_regwidth(instance)
        check_power_of_2(instance, :regwidth, 8)
      end

      def check_accesswidth(instance)
        check_power_of_2(instance, :accesswidth, 8)

        regwidth = instance.property_value(:regwidth)
        accesswidth = instance.property_value(:accesswidth)
        return if accesswidth.value <= regwidth.value

        message = "accesswidth exceeds regwidth: accesswidth = #{accesswidth} regwidth = #{regwidth}"
        raise_evaluation_error message, accesswidth.token_range, regwidth.token_range
      end

      def check_field_ordering(instance)
        mode = bit_allocation_mode(instance)
        instance.instances.each do |field|
          next unless field.msb

          msb = field.msb
          lsb = field.lsb
          next if valid_field_ordering?(mode, msb, lsb)

          message = "invalid field ordering: bit range [#{msb}:#{lsb}] mode #{mode}"
          raise_evaluation_error message, msb.token_range, lsb.token_range
        end
      end

      def bit_allocation_mode(instance)
        (instance.find_addrmap.property_value(:msb0).value && :msb0) || :lsb0
      end

      def valid_field_ordering?(mode, msb, lsb)
        mode == :lsb0 ? msb.value >= lsb.value : msb.value <= lsb.value
      end

      def allocate_bits(instance)
        mode = bit_allocation_mode(instance)
        instance.instances.inject(nil) do |previous_field, field|
          unless field.msb
            msb, lsb = allocate_field_bits(mode, instance, previous_field, field)
            field.msb = msb
            field.lsb = lsb
          end

          field
        end
      end

      def allocate_field_bits(mode, instance, previous_field, field)
        msb, lsb =
          if mode == :lsb0
            allocate_field_bits_lsb0(previous_field, field)
          else
            allocate_field_bits_msb0(instance, previous_field, field)
          end
        [msb, lsb].map { |pos| Value.new(pos, :bit, 64, field.width.token_range) }
      end

      def allocate_field_bits_lsb0(previous_field, field)
        lsb =
          if previous_field
            previous_field.msb.value + 1
          else
            0
          end
        msb = lsb + field.width.value - 1
        [msb, lsb]
      end

      def allocate_field_bits_msb0(instance, previous_field, field)
        lsb =
          if previous_field
            previous_field.msb.value - 1
          else
            instance.property_value(:regwidth).value - 1
          end
        msb = lsb - field.width.value + 1
        [msb, lsb]
      end

      def check_overlapping_fields(instance)
        instance.instances.combination(2).each do |(field_a, field_b)|
          next unless overlapping_field_pair?(field_a, field_b)

          message = 'overlapping fields not allowed'
          raise_evaluation_error message, field_a.token_range, field_b.token_range
        end
      end

      def overlapping_field_pair?(field_a, field_b)
        range_a = field_bit_range(field_a)
        range_b = field_bit_range(field_b)
        return false unless range_a.include?(range_b.begin) || range_b.include?(range_a.begin)

        r_a = field_a.sw_readable?
        w_a = field_a.sw_writable?
        r_b = field_b.sw_readable?
        w_b = field_b.sw_writable?
        (r_a && r_b) || (w_a && w_b)
      end

      def field_bit_range(field)
        pos = [field.msb.value, field.lsb.value].sort
        pos[0]..pos[1]
      end

      def check_fields_out_of_register(instance)
        regwidth = instance.property_value(:regwidth).value
        instance.instances.each do |field|
          next unless field.msb

          msb = field.msb
          lsb = field.lsb
          next if inside_regwidth?(msb, lsb, regwidth)

          message = "field out of register: bit range [#{msb}:#{lsb}] regwidth #{regwidth}"
          raise_evaluation_error message, field.token_range
        end
      end

      def inside_regwidth?(msb, lsb, regwidth)
        range = [msb.value, lsb.value]
        range.none?(&:negative?) && range.sort[1] < regwidth
      end

      def check_fields_spanning_sub_word_boundary(instance)
        accesswidth = instance.property_value(:accesswidth).value
        instance.instances.each do |field|
          next unless field.msb && field_with_side_effect?(field)

          msb = field.msb.value
          lsb = field.lsb.value
          next if (msb / accesswidth) == (lsb / accesswidth)

          message =
            'field spanning sub-word boundary not allowed: ' \
            "bit range [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          raise_evaluation_error message, field.token_range
        end
      end

      def field_with_side_effect?(field)
        sw = field.property_value(:sw).value
        return true if sw in :rw | :w

        [:onread, :rclr, :rset]
          .any? { |prop| field.property_value(prop)&.value }
      end
    end

    class RegInstance < Instance
      include ArrayInstance
      include InstTypeAwareInstance

      attr_accessor :address
      attr_accessor :stride
      attr_accessor :alignment

      def virtual_reg?
        parent.mem?
      end

      def definable?(definition)
        definition.layer in :field
      end

      def instantiable?(definition)
        definable?(definition)
      end

      def accesswidth
        property_value(:accesswidth).value
      end

      def size
        property_value(:regwidth).value / 8
      end

      def sw_readable?
        instances.any?(&:sw_readable?)
      end

      def sw_writable?
        instances.any?(&:sw_writable?)
      end
    end
  end
end
