# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class FieldDefinition < ComponentDefinition
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
        size = inst_values[:array]&.at(0)&.to_value
        return size if size

        instance.property(:fieldwidth)&.value
      end

      def validate(instance)
        check_fieldwidth(instance)
      end

      def check_fieldwidth(instance)
        fieldwidth = instance.property(:fieldwidth)&.value
        return unless fieldwidth

        msb = instance.msb
        lsb = instance.lsb
        width = msb.value - lsb.value + 1
        return if width == fieldwidth.value

        message = "bit width mismatch: instance width #{width} fieldwidth property #{fieldwidth}"
        position = (msb.token_range || lsb.token_range)&.head
        raise_evaluation_error message, position
      end
    end

    class FieldInstance < Instance
      attr_accessor :msb
      attr_accessor :lsb
    end
  end
end
