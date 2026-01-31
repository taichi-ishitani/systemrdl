# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class ExpressionTest < TestCase
      def test_this
        code = 'this'
        assert_parses_expression(s(:this, 'this'), code)
      end

      def test_concatenation
        code = "{a, b, 3'b101, c}"
        assert_parses_expression(
          s(:concatenation,
            reference('a'), reference('b'), verilog_number("3'b101"), reference('c')
          ),
          code
        )

        code = '{4{a}}'
        assert_parses_expression(
          s(:replication, number(4), s(:concatenation, reference('a'))),
          code
        )

        code = '{a, {3{b, c}}}'
        assert_parses_expression(
          s(:concatenation,
            reference('a'),
            s(:replication,
              number(3),
              s(:concatenation, reference('b'), reference('c'))
            )
          ),
          code
        )
      end

      def test_constant_cast
        code = "boolean'(1+2)"
        assert_parses_expression(
          cast(data_type(:boolean), bop('+', number(1), number(2))),
          code
        )

        code = "bit'(1+2)"
        assert_parses_expression(
          cast(data_type(:bit), bop('+', number(1), number(2))),
          code
        )

        code = "longint'(1+2)"
        assert_parses_expression(
          cast(data_type(:longint), bop('+', number(1), number(2))),
          code
        )

        code = "17'(1+2)"
        assert_parses_expression(
          cast(number(17), bop('+', number(1), number(2))),
          code
        )

        code = "(10+7)'(1+2)"
        assert_parses_expression(
          cast(bop('+', number(10), number(7)), bop('+', number(1), number(2))),
          code
        )

        code = "17'(1+2)'(3+4)"
        assert_parses_expression(
          cast(
            cast(number(17), bop('+', number(1), number(2))),
            bop('+', number(3), number(4))
          ),
          code
        )

        code = "longint'(1+2)'(3+4)"
        assert_parses_expression(
          cast(
            cast(data_type(:longint), bop('+', number(1), number(2))),
            bop('+', number(3), number(4))
          ),
          code
        )
      end

      def test_unary_operation
        code = '!a'
        assert_parses_expression(uop('!', reference('a')), code)
        code = '!true'
        assert_parses_expression(uop('!', boolean(true)), code)

        code = '+a'
        assert_parses_expression(uop('+', reference('a')), code)
        code = "+8'hab"
        assert_parses_expression(uop('+', verilog_number("8'hab")), code)

        code = '~a'
        assert_parses_expression(uop('~', reference('a')), code)
        code = "~8'hab"
        assert_parses_expression(uop('~', verilog_number("8'hab")), code)

        code = '&a'
        assert_parses_expression(uop('&', reference('a')), code)
        code = "&8'hab"
        assert_parses_expression(uop('&', verilog_number("8'hab")), code)

        code = '~&a'
        assert_parses_expression(uop('~&', reference('a')), code)
        code = "~&8'hab"
        assert_parses_expression(uop('~&', verilog_number("8'hab")), code)

        code = '|a'
        assert_parses_expression(uop('|', reference('a')), code)
        code = "|8'hab"
        assert_parses_expression(uop('|', verilog_number("8'hab")), code)

        code = '~|a'
        assert_parses_expression(uop('~|', reference('a')), code)
        code = "~|8'hab"
        assert_parses_expression(uop('~|', verilog_number("8'hab")), code)

        code = '^a'
        assert_parses_expression(uop('^', reference('a')), code)
        code = "^8'hab"
        assert_parses_expression(uop('^', verilog_number("8'hab")), code)

        code = '~^a'
        assert_parses_expression(uop('~^', reference('a')), code)
        code = "~^8'hab"
        assert_parses_expression(uop('~^', verilog_number("8'hab")), code)

        code = '^~a'
        assert_parses_expression(uop('^~', reference('a')), code)
        code = "^~8'hab"
        assert_parses_expression(uop('^~', verilog_number("8'hab")), code)
      end

      def test_binary_operation
        code = 'a && b'
        assert_parses_expression(bop('&&', reference('a'), reference('b')), code)
        code = 'true && true'
        assert_parses_expression(bop('&&', boolean(true), boolean(true)), code)
        code = 'true && true && false'
        assert_parses_expression(
          bop('&&', bop('&&', boolean(true), boolean(true)), boolean(false)),
          code
        )

        code = 'a || b'
        assert_parses_expression(bop('||', reference('a'), reference('b')), code)
        code = 'true || true'
        assert_parses_expression(bop('||', boolean(true), boolean(true)), code)
        code = 'true || true || false'
        assert_parses_expression(
          bop('||', bop('||', boolean(true), boolean(true)), boolean(false)),
          code
        )

        code = 'a < b'
        assert_parses_expression(bop('<', reference('a'), reference('b')), code)
        code = '123 < 456'
        assert_parses_expression(bop('<', number(123), number(456)), code)
        code = '123 < 456 < 789'
        assert_parses_expression(
          bop('<', bop('<', number(123), number(456)), number(789)),
          code
        )

        code = 'a > b'
        assert_parses_expression(bop('>', reference('a'), reference('b')), code)
        code = '123 > 456'
        assert_parses_expression(bop('>', number(123), number(456)), code)
        code = '123 > 456 > 789'
        assert_parses_expression(
          bop('>', bop('>', number(123), number(456)), number(789)),
          code
        )

        code = 'a <= b'
        assert_parses_expression(bop('<=', reference('a'), reference('b')), code)
        code = '123 <= 456'
        assert_parses_expression(bop('<=', number(123), number(456)), code)
        code = '123 <= 456 <= 789'
        assert_parses_expression(
          bop('<=', bop('<=', number(123), number(456)), number(789)),
          code
        )

        code = 'a >= b'
        assert_parses_expression(bop('>=', reference('a'), reference('b')), code)
        code = '123 >= 456'
        assert_parses_expression(bop('>=', number(123), number(456)), code)
        code = '123 >= 456 >= 789'
        assert_parses_expression(
          bop('>=', bop('>=', number(123), number(456)), number(789)),
          code
        )

        code = 'a == b'
        assert_parses_expression(bop('==', reference('a'), reference('b')), code)
        code = '123 == 456'
        assert_parses_expression(bop('==', number(123), number(456)), code)
        code = '123 == 456 == 789'
        assert_parses_expression(
          bop('==', bop('==', number(123), number(456)), number(789)),
          code
        )

        code = 'a != b'
        assert_parses_expression(bop('!=', reference('a'), reference('b')), code)
        code = '123 != 456'
        assert_parses_expression(bop('!=', number(123), number(456)), code)
        code = '123 != 456 != 789'
        assert_parses_expression(
          bop('!=', bop('!=', number(123), number(456)), number(789)),
          code
        )

        code = 'a >> b'
        assert_parses_expression(bop('>>', reference('a'), reference('b')), code)
        code = '123 >> 456'
        assert_parses_expression(bop('>>', number(123), number(456)), code)
        code = '123 >> 456 >> 789'
        assert_parses_expression(
          bop('>>', bop('>>', number(123), number(456)), number(789)),
          code
        )

        code = 'a << b'
        assert_parses_expression(bop('<<', reference('a'), reference('b')), code)
        code = '123 << 456'
        assert_parses_expression(bop('<<', number(123), number(456)), code)
        code = '123 << 456 << 789'
        assert_parses_expression(
          bop('<<', bop('<<', number(123), number(456)), number(789)),
          code
        )

        code = 'a & b'
        assert_parses_expression(bop('&', reference('a'), reference('b')), code)
        code = '123 & 456'
        assert_parses_expression(bop('&', number(123), number(456)), code)
        code = '123 & 456 & 789'
        assert_parses_expression(
          bop('&', bop('&', number(123), number(456)), number(789)),
          code
        )

        code = 'a | b'
        assert_parses_expression(bop('|', reference('a'), reference('b')), code)
        code = '123 | 456'
        assert_parses_expression(bop('|', number(123), number(456)), code)
        code = '123 | 456 | 789'
        assert_parses_expression(
          bop('|', bop('|', number(123), number(456)), number(789)),
          code
        )

        code = 'a ^ b'
        assert_parses_expression(bop('^', reference('a'), reference('b')), code)
        code = '123 ^ 456'
        assert_parses_expression(bop('^', number(123), number(456)), code)
        code = '123 ^ 456 ^ 789'
        assert_parses_expression(
          bop('^', bop('^', number(123), number(456)), number(789)),
          code
        )

        code = 'a ~^ b'
        assert_parses_expression(bop('~^', reference('a'), reference('b')), code)
        code = '123 ~^ 456'
        assert_parses_expression(bop('~^', number(123), number(456)), code)
        code = '123 ~^ 456 ~^ 789'
        assert_parses_expression(
          bop('~^', bop('~^', number(123), number(456)), number(789)),
          code
        )

        code = 'a ^~ b'
        assert_parses_expression(bop('^~', reference('a'), reference('b')), code)
        code = '123 ^~ 456'
        assert_parses_expression(bop('^~', number(123), number(456)), code)
        code = '123 ^~ 456 ^~ 789'
        assert_parses_expression(
          bop('^~', bop('^~', number(123), number(456)), number(789)),
          code
        )

        code = 'a * b'
        assert_parses_expression(bop('*', reference('a'), reference('b')), code)
        code = '123 * 456'
        assert_parses_expression(bop('*', number(123), number(456)), code)
        code = '123 * 456 * 789'
        assert_parses_expression(
          bop('*', bop('*', number(123), number(456)), number(789)),
          code
        )

        code = 'a / b'
        assert_parses_expression(bop('/', reference('a'), reference('b')), code)
        code = '123 / 456'
        assert_parses_expression(bop('/', number(123), number(456)), code)
        code = '123 / 456 / 789'
        assert_parses_expression(
          bop('/', bop('/', number(123), number(456)), number(789)),
          code
        )

        code = 'a % b'
        assert_parses_expression(bop('%', reference('a'), reference('b')), code)
        code = '123 % 456'
        assert_parses_expression(bop('%', number(123), number(456)), code)
        code = '123 % 456 % 789'
        assert_parses_expression(
          bop('%', bop('%', number(123), number(456)), number(789)),
          code
        )

        code = 'a + b'
        assert_parses_expression(bop('+', reference('a'), reference('b')), code)
        code = '123 + 456'
        assert_parses_expression(bop('+', number(123), number(456)), code)
        code = '123 + 456 + 789'
        assert_parses_expression(
          bop('+', bop('+', number(123), number(456)), number(789)),
          code
        )

        code = 'a - b'
        assert_parses_expression(bop('-', reference('a'), reference('b')), code)
        code = '123 - 456'
        assert_parses_expression(bop('-', number(123), number(456)), code)
        code = '123 - 456 - 789'
        assert_parses_expression(
          bop('-', bop('-', number(123), number(456)), number(789)),
          code
        )

        code = 'a ** b'
        assert_parses_expression(bop('**', reference('a'), reference('b')), code)
        code = '123 ** 456'
        assert_parses_expression(bop('**', number(123), number(456)), code)
        code = '123 ** 456 ** 789'
        assert_parses_expression(
          bop('**', bop('**', number(123), number(456)), number(789)),
          code
        )
      end

      def test_conditional_operation
        code = 'a ? b : c'
        assert_parses_expression(
          cop(reference('a'), reference('b'), reference('c')),
          code
        )

        code = '1 ? 2 : 3'
        assert_parses_expression(
          cop(number(1), number(2), number(3)),
          code
        )

        code = '1 ? 2 : 3 ? 4 : 5'
        assert_parses_expression(
          cop(number(1), number(2), cop(number(3), number(4), number(5))),
          code
        )

        code = '1 ? 2 ? 3 : 4 : 5 ? 6 : 7'
        assert_parses_expression(
          cop(
            number(1),
            cop(number(2), number(3), number(4)),
            cop(number(5), number(6), number(7))
          ),
          code
        )
      end

      def test_operator_precedence
        code = '+1**2'
        assert_parses_expression(
          bop('**', uop('+', number(1)), number(2)),
          code
        )
        code = '+(1**2)'
        assert_parses_expression(
          uop('+', bop('**', number(1), number(2))),
          code
        )

        code = '1*2**3'
        assert_parses_expression(
          bop('*', number(1), bop('**', number(2), number(3))),
          code
        )
        code = '(1*2)**3'
        assert_parses_expression(
          bop('**', bop('*', number(1), number(2)), number(3)),
          code
        )

        code = '1+2*3'
        assert_parses_expression(
          bop('+', number(1), bop('*', number(2), number(3))),
          code
        )
        code = '(1+2)*3'
        assert_parses_expression(
          bop('*', bop('+', number(1), number(2)), number(3)),
          code
        )

        code = '1<<2+3'
        assert_parses_expression(
          bop('<<', number(1), bop('+', number(2), number(3))),
          code
        )
        code = '(1<<2)+3'
        assert_parses_expression(
          bop('+', bop('<<', number(1), number(2)), number(3)),
          code
        )

        code = '1<2<<3'
        assert_parses_expression(
          bop('<', number(1), bop('<<', number(2), number(3))),
          code
        )
        code = '(1<2)<<3'
        assert_parses_expression(
          bop('<<', bop('<', number(1), number(2)), number(3)),
          code
        )

        code = '1==2<3'
        assert_parses_expression(
          bop('==', number(1), bop('<', number(2), number(3))),
          code
        )
        code = '(1==2)<3'
        assert_parses_expression(
          bop('<', bop('==', number(1), number(2)), number(3)),
          code
        )

        code = '1&2==3'
        assert_parses_expression(
          bop('&', number(1), bop('==', number(2), number(3))),
          code
        )
        code = '(1&2)==3'
        assert_parses_expression(
          bop('==', bop('&', number(1), number(2)), number(3)),
          code
        )

        code = '1^2&3'
        assert_parses_expression(
          bop('^', number(1), bop('&', number(2), number(3))),
          code
        )
        code = '(1^2)&3'
        assert_parses_expression(
          bop('&', bop('^', number(1), number(2)), number(3)),
          code
        )

        code = '1|2^3'
        assert_parses_expression(
          bop('|', number(1), bop('^', number(2), number(3))),
          code
        )
        code = '(1|2)^3'
        assert_parses_expression(
          bop('^', bop('|', number(1), number(2)), number(3)),
          code
        )

        code = '1&&2|3'
        assert_parses_expression(
          bop('&&', number(1), bop('|', number(2), number(3))),
          code
        )
        code = '(1&&2)|3'
        assert_parses_expression(
          bop('|', bop('&&', number(1), number(2)), number(3)),
          code
        )

        code = '1||2&&3'
        assert_parses_expression(
          bop('||', number(1), bop('&&', number(2), number(3))),
          code
        )
        code = '(1||2)&&3'
        assert_parses_expression(
          bop('&&', bop('||', number(1), number(2)), number(3)),
          code
        )

        code = '1||2?3:4'
        assert_parses_expression(
          cop(bop('||', number(1), number(2)), number(3), number(4)),
          code
        )
        code = '1||(2?3:4)'
        assert_parses_expression(
          bop('||', number(1), cop(number(2), number(3), number(4))),
          code
        )
      end

      def reference(id)
        s(:instance_ref, s(:instance_ref_element, s(:id, id)))
      end

      def boolean(value)
        s(:boolean, value.to_s)
      end

      def number(number)
        s(:number, number.to_s)
      end

      def verilog_number(number)
        s(:verilog_number, number)
      end

      def data_type(type)
        s(:data_type, type.to_s)
      end

      def cast(casting_type, expression)
        s(:cast, casting_type, expression)
      end

      def uop(operator, expression)
        s(:unary_operation, operator, expression)
      end

      def bop(operator, lhs, rhs)
        s(:binary_operation, operator, lhs, rhs)
      end

      def cop(condition, if_expression, else_expression)
        s(:conditional_operation, condition, if_expression, else_expression)
      end
    end
  end
end
