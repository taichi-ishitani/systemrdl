# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegFile < TestCase
      def test_property_initialization
        regfile = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            regfile {} my_regfile;
          };
        RDL

        assert_property(regfile, :name, :string, value: 'my_regfile')
        assert_property(regfile, :desc, :string, value: '')
        assert_property(regfile, :alignment, :longint)
        assert_property(regfile, :sharedextbus, :boolean, value: false)
        assert_property(regfile, :errextbus, :boolean, value: false)
      end
    end
  end
end
