# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMap < TestCase
      def test_initial_property_value
        addrmap = evaluate(<<~'RDL').instances[0]
          addrmap some_reg {};
        RDL

        assert_property(addrmap, :alignment, :longint)
      end
    end
  end
end
