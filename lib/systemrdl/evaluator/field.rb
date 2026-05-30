# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class FieldDefinition < ComponentDefinition
      private

      def instnace_class
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
    end

    class FieldInstance < Instance
    end
  end
end
