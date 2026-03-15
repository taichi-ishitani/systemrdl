# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestReg < TestCase
      def test_property_initialization
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            reg {} my_reg;
          };
        RDL

        assert_property(reg, :name, :string, value: 'my_reg')
        assert_property(reg, :desc, :string, value: '')
        assert_property(reg, :regwidth, :longint)
        assert_property(reg, :accesswidth, :longint)
        assert_property(reg, :errextbus, :boolean, value: false)
        # todo
        # assert_property(reg, :intr)
        # assert_property(reg, :halt)
        assert_property(reg, :shared, :boolean, value: false)
      end
    end
  end
end
