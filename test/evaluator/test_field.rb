# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestField < TestCase
      def test_property_initialization
        field = evaluate(<<~'RDL').instances[0].instances[0].instances[0]
          addrmap some_reg {
            reg {
              field {} my_field;
            } my_reg;
          };
        RDL

        assert_property(field, :name, [:string], value: 'my_field')
        assert_property(field, :desc, [:string], value: '')

        # Field access properties
        assert_property(field, :hw, [:access_type], value: :rw)
        assert_property(field, :sw, [:access_type], value: :rw)

        # Hardware signal properties
        assert_property(field, :next, [:reference])
        assert_property(field, :reset, [:bit, :reference])
        assert_property(field, :resetsignal, [:reference])

        # Software access properties
        assert_property(field, :rclr, [:boolean], value: false)
        assert_property(field, :rset, [:boolean], value: false)
        assert_property(field, :onread, [:on_read_type])
        assert_property(field, :woset, [:boolean], value: false)
        assert_property(field, :woclr, [:boolean], value: false)
        assert_property(field, :onwrite, [:on_write_type])
        assert_property(field, :swwe, [:boolean, :reference], value: false)
        assert_property(field, :swwel, [:boolean, :reference], value: false)
        assert_property(field, :swmod, [:boolean], value: false)
        assert_property(field, :swacc, [:boolean], value: false)
        assert_property(field, :singlepulse, [:boolean], value: false)

        # Hardware access properties
        assert_property(field, :we, [:boolean, :reference], value: false)
        assert_property(field, :wel, [:boolean, :reference], value: false)
        assert_property(field, :anded, [:boolean], value: false)
        assert_property(field, :ored, [:boolean], value: false)
        assert_property(field, :xored, [:boolean], value: false)
        assert_property(field, :fieldwidth, [:longint])
        assert_property(field, :hwclr, [:boolean, :reference], value: false)
        assert_property(field, :hwset, [:boolean, :reference], value: false)
        assert_property(field, :hwenable, [:reference])
        assert_property(field, :hwmask, [:reference])

        # Counter properties
        # TODO

        # Interrupt properties
        # TODO

        # Miscellaneous field properties
        # TODO
        # assert_property(field, :encode)
        assert_property(field, :precedence, [:precedence_type], value: :sw)
        assert_property(field, :paritycheck, [:boolean], value: false)
      end
    end
  end
end
