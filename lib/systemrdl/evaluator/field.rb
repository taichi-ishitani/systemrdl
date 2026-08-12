# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class FieldDefinition < ComponentDefinition
      def validate(instance)
        check_fieldwidth(instance)
        check_reset(instance)
        check_sw_hw_access_combination(instance)
        check_onread_exclusivity(instance)
        check_sw_read_access_required(instance)
        check_onwrite_exclusivity(instance)
        check_sw_write_access_required(instance)
        check_swwe_swwel_exclusivity(instance)
        check_we_wel_exclusivity(instance)
        check_we_required(instance)
      end

      def revalidate(instance)
        check_reset(instance)
        check_sw_hw_access_combination(instance)
        check_onread_exclusivity(instance)
        check_sw_read_access_required(instance)
        check_onwrite_exclusivity(instance)
        check_sw_write_access_required(instance)
        check_swwe_swwel_exclusivity(instance)
        check_we_wel_exclusivity(instance)
        check_we_required(instance)
      end

      def layer
        :field
      end

      def support_inst_type?(inst_type)
        inst_type.nil?
      end

      private

      def instance_class
        FieldInstance
      end

      def apply_inst_values(instance, inst_values)
        assign_bit_range(instance, inst_values)
        apply_reset_value(instance, inst_values)
        check_address_allocation_operator(inst_values)
      end

      def assign_bit_range(instance, inst_values)
        if (range = inst_values[:range])
          msb, lsb = range.elements
          instance.msb = msb
          instance.lsb = lsb
        else
          instance.width = bit_width(instance, inst_values)
        end
      end

      def bit_width(instance, inst_values)
        size = inst_values[:array]
        unless size
          if (fieldwidth = instance.property_value(:fieldwidth))
            return fieldwidth
          else
            return Value.new(1, :bit, 64, nil)
          end
        end

        if size.size >= 2
          message = 'multidimensional size specification not allowed for field'
          raise_evaluation_error message, size.token_range
        end

        size = size.elements[0]
        if size.value == 0
          message = 'bit width must be positive'
          raise_evaluation_error message, size.token_range
        end

        size
      end

      def check_fieldwidth(instance)
        fieldwidth = instance.property_value(:fieldwidth)
        return unless fieldwidth

        if fieldwidth.value == 0
          message = 'fieldwidth must be positive'
          raise_evaluation_error message, fieldwidth.token_range
        end

        width, width_token_range = extract_width(instance)
        return if width == fieldwidth.value

        message = "bit width mismatch: instance width #{width} fieldwidth property #{fieldwidth}"
        raise_evaluation_error message, *width_token_range
      end

      def extract_width(instance)
        if instance.msb
          pos = [instance.msb.value, instance.lsb.value].sort
          width = pos[1] - pos[0] + 1
          [width, [instance.msb.token_range, instance.lsb.token_range]]
        else
          [instance.width.value, [instance.width.token_range].compact]
        end
      end

      def apply_reset_value(instance, inst_values)
        value = inst_values[:reset_value]
        return unless value

        property = instance.property(:reset)
        property.assign(value)
      end

      def check_reset(instance)
        reset_value = instance.property_value(:reset)
        return unless reset_value

        if reset_value.type in :field_reference | :property_reference
          # TODO
          # check width of the specified instance or property
        else
          check_reset_value(instance, reset_value)
        end
      end

      def check_reset_value(instance, reset_value)
        width, _ = extract_width(instance)
        range = 0..((2**width) - 1)
        return if range.include?(reset_value.value)

        message =
          format(
            'reset value out of range: value 0x%<reset_value>x range 0x%<begin>x..0x%<end>x',
            reset_value: reset_value.value, begin: range.begin, end: range.end
          )
        raise_evaluation_error message, reset_value.token_range
      end

      def check_address_allocation_operator(inst_values)
        [:address_assignment, :address_stride, :address_alignment].each do |op|
          value = inst_values[op]
          next unless value

          message = 'address allocation operator not allowed for field instance'
          raise_evaluation_error message, value.token_range
        end
      end

      def check_sw_hw_access_combination(instance)
        sw = instance.property_value(:sw)
        hw = instance.property_value(:hw)

        combination = [sw.value, hw.value]
        return unless combination in [:w, :w] | [:w, :na] | [:na, *]

        message = "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
        raise_evaluation_error message, sw.token_range, hw.token_range
      end

      def check_onread_exclusivity(instance)
        check_property_exclusivity(instance, [:onread, :rclr, :rset])
      end

      def check_sw_read_access_required(instance)
        kind, onread = {
          onread: instance.property_value(:onread),
          rclr: instance.property_value(:rclr),
          rset: instance.property_value(:rset)
        }.find { |_, v| v&.value }

        return unless onread

        sw = instance.property_value(:sw)
        return if sw.value in :rw | :r

        onread_normalized = (kind == :onread && onread.value) || kind
        message = "sw read access required: onread = #{onread_normalized} sw = #{sw}"
        raise_evaluation_error message, onread.token_range, sw.token_range
      end

      def check_onwrite_exclusivity(instance)
        check_property_exclusivity(instance, [:onwrite, :woset, :woclr])
      end

      def check_sw_write_access_required(instance)
        kind, onwrite = {
          onwrite: instance.property_value(:onwrite),
          woset: instance.property_value(:woset),
          woclr: instance.property_value(:woclr)
        }.find { |(_, v)| v&.value }

        return unless onwrite

        sw = instance.property_value(:sw)
        return if sw.value in :rw | :w

        onwrite_normalized = (kind == :onwrite && onwrite.value) || kind
        message = "sw write access required: onwrite = #{onwrite_normalized} sw = #{sw}"
        raise_evaluation_error message, onwrite.token_range, sw.token_range
      end

      def check_swwe_swwel_exclusivity(instance)
        check_property_exclusivity(instance, [:swwe, :swwel])
      end

      def check_we_wel_exclusivity(instance)
        check_property_exclusivity(instance, [:we, :wel])
      end

      def check_we_required(instance)
        sw = instance.property_value(:sw)
        return if sw.value == :r

        hw = instance.property_value(:hw)
        return if hw.value in :r | :na

        we = instance.property_value(:we)
        return if we.value

        wel = instance.property_value(:wel)
        return if wel.value

        message = "hw write enable required: sw = #{sw} hw = #{hw}"
        raise_evaluation_error message, sw.token_range, hw.token_range
      end
    end

    class FieldInstance < Instance
      attr_accessor :msb
      attr_accessor :lsb
      attr_accessor :width

      def virtual_field?
        parent.virtual_reg?
      end

      def definable?(_definition)
        false
      end

      def instantiable?(_definition)
        false
      end

      def sw_readable?
        property_value(:sw).value in :rw | :rw1 | :r
      end

      def sw_writable?
        property_value(:sw).value in :rw | :rw1 | :w | :w1
      end
    end
  end
end
