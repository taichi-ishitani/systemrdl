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

      private

      def instance_class
        FieldInstance
      end

      def apply_inst_values(instance, inst_values)
        assign_bit_pos(instance, inst_values)
        apply_reset_value(instance, inst_values)
      end

      def assign_bit_pos(instance, inst_values)
        msb, lsb =
          if (range = inst_values[:range])
            range.elements
          else
            calc_bit_pos(instance, inst_values)
          end
        instance.msb = msb
        instance.lsb = lsb
      end

      def calc_bit_pos(instance, inst_values)
        width = calc_bit_width(instance, inst_values)
        last_msb = instance.parent.instances.last&.msb
        lsb = (last_msb&.value || -1) + 1
        msb = lsb + (width&.value || 1) - 1
        [msb, lsb].map { |pos| Value.new(pos, :bit, 64, width&.token_range) }
      end

      def calc_bit_width(instance, inst_values)
        size = inst_values[:array]
        return instance.property_value(:fieldwidth) unless size

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

        msb = instance.msb
        lsb = instance.lsb
        width = msb.value - lsb.value + 1
        return if width == fieldwidth.value

        message = "bit width mismatch: instance width #{width} fieldwidth property #{fieldwidth}"
        raise_evaluation_error message, msb.token_range, lsb.token_range
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
        width = instance.msb.value - instance.lsb.value + 1
        range = 0..((2**width) - 1)
        return if range.include?(reset_value.value)

        message =
          format(
            'reset value out of range: value 0x%<reset_value>x range 0x%<begin>x..0x%<end>x',
            reset_value: reset_value.value, begin: range.begin, end: range.end
          )
        raise_evaluation_error message, reset_value.token_range
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

      def layer
        :field
      end

      def definable?(_definition)
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
