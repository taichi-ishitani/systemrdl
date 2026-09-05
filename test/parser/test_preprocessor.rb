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

      def test_text_macro
        code = <<~'RDL'
          `define add 1 + 2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        #ode = <<~'RDL'
        # `define add 1 + 2
        # `add()
        #DL
        #ssert_parses_expression(
        # s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
        # code
        #

        code = <<~'RDL'
          `define add \
          1 + 2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define add 1 \
          + \
          2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define one 1
          `define add `one + 2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define one 1
          `one + `one
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '1')),
          code
        )

        code = <<~'RDL'
          `define add 1 + \
          // comment \
          2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define add 1 + \
          /*
           * comment
           */ 2
          `add
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define empty
          1 `empty + 2 `empty
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )
      end

      def test_text_macro_with_args
        code = <<~'RDL'
          `define add(a) a + a
          `add(1)
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '1')),
          code
        )

        code = <<~'RDL'
          `define add(a, b) a + b
          `add(1, 2)
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define add(a, b) a + b
          `add(1 + 2, 3 + 4)
        RDL
        assert_parses_expression(
          s(:binary_operation, '+',
            s(:binary_operation, '+',
              s(:binary_operation, '+',
                s(:number, '1'),
                s(:number, '2')
              ),
              s(:number, '3')
            ),
            s(:number, '4')
          ),
          code
        )

        code = <<~'RDL'
          `define add(a, b) a + b
          `add((1 + 2), (3 + 4))
        RDL
        assert_parses_expression(
          s(:binary_operation, '+',
            s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
            s(:binary_operation, '+', s(:number, '3'), s(:number, '4'))
          ),
          code
        )

        code = <<~'RDL'
          `define concat(a, b, c) {a, b, c}
          `concat(8'd1, {8'd2, 8'd3}, {{8'd4, 8'd5}, {8'd6, 8'd7}})
        RDL
        assert_parses_expression(
          s(:concatenation,
            s(:verilog_number, "8'd1"),
            s(
              :concatenation,
              s(:verilog_number, "8'd2"), s(:verilog_number, "8'd3")
            ),
            s(
              :concatenation,
              s(
                :concatenation,
                s(:verilog_number, "8'd4"), s(:verilog_number, "8'd5")
              ),
              s(
                :concatenation,
                s(:verilog_number, "8'd6"), s(:verilog_number, "8'd7")
              )
            )
          ),
          code
        )

        code = <<~'RDL'
          `define add(a, b) a + b
          `add(`add(1, 2), `add(3, 4))
        RDL
        assert_parses_expression(
          s(:binary_operation, '+',
            s(:binary_operation, '+',
              s(:binary_operation, '+',
                s(:number, '1'),
                s(:number, '2')
              ),
              s(:number, '3')
            ),
            s(:number, '4')
          ),
          code
        )

        code = <<~'RDL'
          `define add_2(a) a + 2
          `define add_4(a) a + 4
          `define add(a, b) `add_2(a) + `add_4(b)
          `add(1, 3)
        RDL
        assert_parses_expression(
          s(:binary_operation, '+',
            s(:binary_operation, '+',
              s(:binary_operation, '+',
                s(:number, '1'),
                s(:number, '2')
              ),
              s(:number, '3')
            ),
            s(:number, '4')
          ),
          code
        )
      end

      def test_undef
        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            1
          `else
            2
          `endif
          +
          `undef FOO
          `ifdef FOO
            1
          `else
            2
          `endif
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '2')),
          code
        )

        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            1
          `else
            2
          `endif
          +
          `undef BAR
          `ifdef FOO
            1
          `else
            2
          `endif
        RDL
        assert_parses_expression(
          s(:binary_operation, '+', s(:number, '1'), s(:number, '1')),
          code
        )
      end
    end
  end
end
