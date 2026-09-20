# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestParameterizedComponent < TestCase
      def test_instantiating_parameterized_component
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            field my_field #(
              onwritetype       ONWRITE     = woset,
              longint unsigned  FIELDWIDTH  = 1
            ) {
              sw = rw;
              hw = r;
              onwrite = ONWRITE;
              fieldwidth = FIELDWIDTH;
            };
            reg {
              my_field a;
              my_field #(.ONWRITE(woclr)) b;
              my_field #(.FIELDWIDTH(2)) c;
              my_field #(.ONWRITE(wot), .FIELDWIDTH(3)) d;
            } a;
          };
        RDL

        assert_property_value(fields[0], :onwrite, :woset)
        assert_property_value(fields[0], :fieldwidth, 1)

        assert_property_value(fields[1], :onwrite, :woclr)
        assert_property_value(fields[1], :fieldwidth, 1)

        assert_property_value(fields[2], :onwrite, :woset)
        assert_property_value(fields[2], :fieldwidth, 2)

        assert_property_value(fields[3], :onwrite, :wot)
        assert_property_value(fields[3], :fieldwidth, 3)
      end

      def test_parameter_dependency
        mems = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            mem fixed_mem #(
              longint unsigned word_size   = 32,
              longint unsigned memory_size = word_size * 4096
            ) {
              mementries = memory_size / word_size;
              memwidth   = word_size;
            };
            external fixed_mem a;
            external fixed_mem #(.word_size(64)) b;
            external fixed_mem #(.memory_size(1024)) c;
          };
        RDL

        assert_property_value(mems[0], :mementries, 4096)
        assert_property_value(mems[0], :memwidth, 32)

        assert_property_value(mems[1], :mementries, 4096)
        assert_property_value(mems[1], :memwidth, 64)

        assert_property_value(mems[2], :mementries, 32)
        assert_property_value(mems[2], :memwidth, 32)
      end
    end
  end
end
