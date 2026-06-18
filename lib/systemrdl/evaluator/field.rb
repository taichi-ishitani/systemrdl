# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class FieldDefinition < ComponentDefinition
      def validate(instance)
        check_fieldwidth(instance)
        check_reset_value(instance)
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
        check_reset_value(instance)
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

      def init_properties(instance)
        super

        #
        # Table 11—Field access properties
        #
        create_property(instance, :hw, [:access_type], :rw)
        create_property(instance, :sw, [:access_type], :rw)

        #
        # Table 13—Hardware signal properties
        #
        create_property(instance, :next, [:reference], nil)
        create_property(instance, :reset, [:bit, :reference], nil)
        create_property(instance, :resetsignal, [:reference], nil)

        #
        # Table 14—Software access properties
        #
        create_property(instance, :rclr, [:boolean], false)
        create_property(instance, :rset, [:boolean], false)
        create_property(instance, :onread, [:on_read_type], nil)
        create_property(instance, :woset, [:boolean], false)
        create_property(instance, :woclr, [:boolean], false)
        create_property(instance, :onwrite, [:on_write_type], nil)
        create_property(instance, :swwe, [:boolean, :reference], false)
        create_property(instance, :swwel, [:boolean, :reference], false)
        create_property(instance, :swmod, [:boolean], false)
        create_property(instance, :swacc, [:boolean], false)
        create_property(instance, :singlepulse, [:boolean], false)

        #
        # Table 18—Hardware access properties
        #
        create_property(instance, :we, [:boolean, :reference], false)
        create_property(instance, :wel, [:boolean, :reference], false)
        create_property(instance, :anded, [:boolean], false)
        create_property(instance, :ored, [:boolean], false)
        create_property(instance, :xored, [:boolean], false)
        create_property(instance, :fieldwidth, [:longint], nil)
        create_property(instance, :hwclr, [:boolean, :reference], false)
        create_property(instance, :hwset, [:boolean, :reference], false)
        create_property(instance, :hwenable, [:reference], nil)
        create_property(instance, :hwmask, [:reference], nil)

        #
        # Table 19—Counter field properties
        #
        # TODO

        #
        # Table 21—Field access interrupt properties
        #
        # TODO

        #
        # Table 22—Miscellaneous properties
        #
        # create_property(:encode) TODO
        create_property(instance, :precedence, [:precedence_type], :sw)
        create_property(instance, :paritycheck, [:boolean], false)
      end

      def apply_inst_values(instance, inst_values)
        assign_bit_pos(instance, inst_values)
        apply_reset_value(instance, inst_values)
      end

      def assign_bit_pos(instance, inst_values)
        msb, lsb =
          if (range = inst_values[:range])
            range.map(&:to_value)
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
        [msb, lsb].map { |pos| Value.new(pos, width&.token_range) }
      end

      def calc_bit_width(instance, inst_values)
        size = inst_values[:array]
        return instance.property_value(:fieldwidth) unless size

        if size.values.size >= 2
          message = 'multidimensional size specification not allowed for field'
          raise_evaluation_error message, size.token_range
        end

        size = size.values[0]
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
        property.assign(value.to_value)
      end

      def check_reset_value(instance)
        reset_value = instance.property_value(:reset)
        return unless reset_value

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

      def check_property_exclusivity(instance, names, error_message)
        properties =
          names
            .map { |name| instance.property_value(name) }
            .select { |v| v&.value }
        return if properties.size <= 1

        raise_evaluation_error error_message, *properties.map(&:token_range)
      end

      def check_onread_exclusivity(instance)
        check_property_exclusivity(
          instance, [:onread, :rclr, :rset],
          'onread, rclr and rset properties are mutually exclusive'
        )
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
        check_property_exclusivity(
          instance, [:onwrite, :woset, :woclr],
          'onwrite, woset and woclr properties are mutually exclusive'
        )
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
        check_property_exclusivity(
          instance, [:swwe, :swwel],
          'swwe and swwel properties are mutually exclusive'
        )
      end

      def check_we_wel_exclusivity(instance)
        check_property_exclusivity(
          instance, [:we, :wel],
          'we and wel properties are mutually exclusive'
        )
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

      def instantiable?(_definition)
        false
      end
    end
  end
end
