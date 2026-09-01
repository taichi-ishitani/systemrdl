# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestPreProcessor < TestCase
      def test_ifdef
        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            "foo"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `ifdef FOO
            "foo"
          `endif
          "bar"
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            "foo"
          `else
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `ifdef FOO
            "foo"
          `else
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `define BAR
          `ifdef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `ifdef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
          "baz"
        RDL
        assert_parses_expression(s(:string, '"baz"'), code)

        code = <<~'RDL'
          `ifdef FOO
            "foo"
          `elsif BAR
            "bar"
          `else
            "baz"
          `endif
        RDL
        assert_parses_expression(s(:string, '"baz"'), code)
      end

      def test_ifndef
        code = <<~'RDL'
          `ifndef FOO
            "foo"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `define FOO
          `ifndef FOO
            "foo"
          `endif
          "bar"
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `ifndef FOO
            "foo"
          `else
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `define FOO
          `ifndef FOO
            "foo"
          `else
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `ifndef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `define FOO
          `define BAR
          `ifndef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `define FOO
          `ifndef FOO
            "foo"
          `elsif BAR
            "bar"
          `endif
          "baz"
        RDL
        assert_parses_expression(s(:string, '"baz"'), code)

        code = <<~'RDL'
          `define FOO
          `ifndef FOO
            "foo"
          `elsif BAR
            "bar"
          `else
            "baz"
          `endif
        RDL
        assert_parses_expression(s(:string, '"baz"'), code)
      end

      def test_include
        code = <<~'RDL'
          `include "test/fixtures/include/foo.rdl"
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)

        code = <<~'RDL'
          `include "foo.rdl"
        RDL
        assert_parses_expression(
          s(:string, '"foo"'), code,
          incdirs: ['test/fixtures/include']
        )

        code = <<~'RDL'
          `include "bar.rdl"
        RDL
        assert_parses_expression(
          s(:string, '"bar_1"'), code,
          incdirs: ['test/fixtures/include/bar_1', 'test/fixtures/include/bar_2']
        )
      end
    end
  end
end
