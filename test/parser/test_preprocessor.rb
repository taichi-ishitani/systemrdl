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

      def test_illegal_character_in_true_branch
        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            $invalid
          `endif
          "bar"
        RDL
        assert_raises_parse_error(
          code,
          'syntax error on value \'$\' (ILLEGAL_CHARACTER)'
        )

        code = <<~'RDL'
          `define FOO
          `ifdef FOO
            ` invalid
          `endif
          "bar"
        RDL
        assert_raises_parse_error(
          code,
          'syntax error on value \'`\' (ILLEGAL_CHARACTER)'
        )
      end

      def test_illegal_character_in_false_branch
        code = <<~'RDL'
          `ifdef FOO
            $invalid
          `endif
          "bar"
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)

        code = <<~'RDL'
          `ifdef FOO
            ` invalid
          `endif
          "bar"
        RDL
        assert_parses_expression(s(:string, '"bar"'), code)
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

      def test_include_file_not_found
        code = <<~'RDL'
          `include "test/fixtures/include/baz.rdl"
        RDL
        assert_raises_preprocess_error(
          code,
          'include file not found: test/fixtures/include/baz.rdl'
        )
      end

      def test_include_nesting_too_deep
        code = <<~'RDL'
          `include "test/fixtures/include/nest/nest_1.rdl"
        RDL
        assert_raises_preprocess_error(
          code,
          'include nesting too deep: test/fixtures/include/nest/nest_16.rdl limit 15'
        )
        assert_raises_preprocess_error(
          code,
          'include nesting too deep: test/fixtures/include/nest/nest_9.rdl limit 8',
          include_limit: 8
        )

        code = <<~'RDL'
          `include "test/fixtures/include/nest/recursive.rdl"
        RDL
        assert_raises_preprocess_error(
          code,
          'include nesting too deep: test/fixtures/include/nest/recursive.rdl limit 15'
        )
        assert_raises_preprocess_error(
          code,
          'include nesting too deep: test/fixtures/include/nest/recursive.rdl limit 8',
          include_limit: 8
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

      def test_illegal_character_in_unused_macro
        code = <<~'RDL'
          `define FOO "foo"
          `define BAR $invalid
          `FOO
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)
      end

      def test_illegal_character_in_unused_macro_arg
        code = <<~'RDL'
          `define FOO(a, b) a
          `FOO("foo", $invalid)
        RDL
        assert_parses_expression(s(:string, '"foo"'), code)
      end

      def test_using_undefined_macro
        code = <<~'RDL'
          `define add(a) a + a
          `sub(1)
        RDL
        assert_raises_preprocess_error(
          code,
          'undefined macro: sub'
        )
      end

      def test_macro_usage_with_arity_mismatch
        code = <<~'RDL'
          `define foo(a, b)
          `foo(1)
        RDL
        assert_raises_preprocess_error(
          code,
          'wrong number of arguments for macro foo: expected 2 actual 1'
        )

        code = <<~'RDL'
          `define foo(a)
          `foo(1, 2)
        RDL
        assert_raises_preprocess_error(
          code,
          'wrong number of arguments for macro foo: expected 1 actual 2'
        )
      end

      def test_recursive_macro_usage
        code = <<~'RDL'
          `define FOO `FOO
          `FOO
        RDL
        assert_raises_preprocess_error(
          code,
          'recursive macro usage: FOO'
        )

        code = <<~'RDL'
          `define FOO `BAR
          `define BAR `FOO
          `FOO
        RDL
        assert_raises_preprocess_error(
          code,
          'recursive macro usage: FOO'
        )
      end

      def test_parameterless_macro_with_parens
        code = <<~'RDL'
          `define FOO 1
          `FOO()
        RDL
        assert_raises_parse_error(
          code,
          'syntax error on value \'(\' (()',
          test: :constant_expression
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
