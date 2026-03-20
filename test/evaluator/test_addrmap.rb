# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMap < TestCase
      def test_property_initialization
        addrmap = evaluate(<<~'RDL').instances[0]
          addrmap some_reg {};
        RDL

        assert_property(addrmap, :name, [:string], value: 'some_reg')
        assert_property(addrmap, :desc, [:string], value: '')
        assert_property(addrmap, :alignment, [:longint])
        assert_property(addrmap, :sharedextbus, [:boolean], value: false)
        assert_property(addrmap, :errextbus, [:boolean], value: false)
        assert_property(addrmap, :bigendian, [:boolean], value: false)
        assert_property(addrmap, :littleendian, [:boolean], value: false)
        assert_property(addrmap, :addressing, [:addressing_type], value: :regalign)
        assert_property(addrmap, :rsvdset, [:boolean], value: false)
        assert_property(addrmap, :rsvdsetX, [:boolean], value: false)
        assert_property(addrmap, :msb0, [:boolean], value: false)
        assert_property(addrmap, :lsb0, [:boolean], value: false)
      end
    end
  end
end
