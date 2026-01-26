# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class ExpressionTest < TestCase
      def test_this
        code = 'this'
        assert_parses(s(:this, 'this'), code, test: true)
      end

      def test_concatenation
        code = "{a, b, 3'b101, c}"
        assert_parses(
          s(:concatenation,
            reference('a'), reference('b'), verilog_number("3'b101"), reference('c')
          ),
          code, test: true
        )

        code = '{4{a}}'
        assert_parses(
          s(:replication, number(4), s(:concatenation, reference('a'))),
          code, test: true
        )

        code = '{a, {3{b, c}}}'
        assert_parses(
          s(:concatenation,
            reference('a'),
            s(:replication,
              number(3),
              s(:concatenation, reference('b'), reference('c'))
            )
          ),
          code, test: true
        )
      end

      def test_constant_cast
        code = "boolean'(1+2)"
        assert_parses(
          cast(data_type(:boolean), bop('+', number(1), number(2))),
          code, test: true
        )

        code = "bit'(1+2)"
        assert_parses(
          cast(data_type(:bit), bop('+', number(1), number(2))),
          code, test: true
        )

        code = "longint'(1+2)"
        assert_parses(
          cast(data_type(:longint), bop('+', number(1), number(2))),
          code, test: true
        )

        code = "17'(1+2)"
        assert_parses(
          cast(number(17), bop('+', number(1), number(2))),
          code, test: true
        )

        code = "(10+7)'(1+2)"
        assert_parses(
          cast(bop('+', number(10), number(7)), bop('+', number(1), number(2))),
          code, test: true
        )

        code = "17'(1+2)'(3+4)"
        assert_parses(
          cast(
            cast(number(17), bop('+', number(1), number(2))),
            bop('+', number(3), number(4))
          ),
          code, test: true
        )

        code = "longint'(1+2)'(3+4)"
        assert_parses(
          cast(
            cast(data_type(:longint), bop('+', number(1), number(2))),
            bop('+', number(3), number(4))
          ),
          code, test: true
        )
      end

      def test_unary_operation
        code = '!a'
        assert_parses(uop('!', reference('a')), code, test: true)
        code = '!true'
        assert_parses(uop('!', boolean(true)), code, test: true)

        code = '+a'
        assert_parses(uop('+', reference('a')), code, test: true)
        code = "+8'hab"
        assert_parses(uop('+', verilog_number("8'hab")), code, test: true)

        code = '~a'
        assert_parses(uop('~', reference('a')), code, test: true)
        code = "~8'hab"
        assert_parses(uop('~', verilog_number("8'hab")), code, test: true)

        code = '&a'
        assert_parses(uop('&', reference('a')), code, test: true)
        code = "&8'hab"
        assert_parses(uop('&', verilog_number("8'hab")), code, test: true)

        code = '~&a'
        assert_parses(uop('~&', reference('a')), code, test: true)
        code = "~&8'hab"
        assert_parses(uop('~&', verilog_number("8'hab")), code, test: true)

        code = '|a'
        assert_parses(uop('|', reference('a')), code, test: true)
        code = "|8'hab"
        assert_parses(uop('|', verilog_number("8'hab")), code, test: true)

        code = '~|a'
        assert_parses(uop('~|', reference('a')), code, test: true)
        code = "~|8'hab"
        assert_parses(uop('~|', verilog_number("8'hab")), code, test: true)

        code = '^a'
        assert_parses(uop('^', reference('a')), code, test: true)
        code = "^8'hab"
        assert_parses(uop('^', verilog_number("8'hab")), code, test: true)

        code = '~^a'
        assert_parses(uop('~^', reference('a')), code, test: true)
        code = "~^8'hab"
        assert_parses(uop('~^', verilog_number("8'hab")), code, test: true)

        code = '^~a'
        assert_parses(uop('^~', reference('a')), code, test: true)
        code = "^~8'hab"
        assert_parses(uop('^~', verilog_number("8'hab")), code, test: true)
      end

      def test_binary_operation
        code = 'a && b'
        assert_parses(bop('&&', reference('a'), reference('b')), code, test: true)
        code = 'true && true'
        assert_parses(bop('&&', boolean(true), boolean(true)), code, test: true)
        code = 'true && true && false'
        assert_parses(
          bop('&&', bop('&&', boolean(true), boolean(true)), boolean(false)),
          code, test: true
        )

        code = 'a || b'
        assert_parses(bop('||', reference('a'), reference('b')), code, test: true)
        code = 'true || true'
        assert_parses(bop('||', boolean(true), boolean(true)), code, test: true)
        code = 'true || true || false'
        assert_parses(
          bop('||', bop('||', boolean(true), boolean(true)), boolean(false)),
          code, test: true
        )

        code = 'a < b'
        assert_parses(bop('<', reference('a'), reference('b')), code, test: true)
        code = '123 < 456'
        assert_parses(bop('<', number(123), number(456)), code, test: true)
        code = '123 < 456 < 789'
        assert_parses(
          bop('<', bop('<', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a > b'
        assert_parses(bop('>', reference('a'), reference('b')), code, test: true)
        code = '123 > 456'
        assert_parses(bop('>', number(123), number(456)), code, test: true)
        code = '123 > 456 > 789'
        assert_parses(
          bop('>', bop('>', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a <= b'
        assert_parses(bop('<=', reference('a'), reference('b')), code, test: true)
        code = '123 <= 456'
        assert_parses(bop('<=', number(123), number(456)), code, test: true)
        code = '123 <= 456 <= 789'
        assert_parses(
          bop('<=', bop('<=', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a >= b'
        assert_parses(bop('>=', reference('a'), reference('b')), code, test: true)
        code = '123 >= 456'
        assert_parses(bop('>=', number(123), number(456)), code, test: true)
        code = '123 >= 456 >= 789'
        assert_parses(
          bop('>=', bop('>=', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a == b'
        assert_parses(bop('==', reference('a'), reference('b')), code, test: true)
        code = '123 == 456'
        assert_parses(bop('==', number(123), number(456)), code, test: true)
        code = '123 == 456 == 789'
        assert_parses(
          bop('==', bop('==', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a != b'
        assert_parses(bop('!=', reference('a'), reference('b')), code, test: true)
        code = '123 != 456'
        assert_parses(bop('!=', number(123), number(456)), code, test: true)
        code = '123 != 456 != 789'
        assert_parses(
          bop('!=', bop('!=', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a >> b'
        assert_parses(bop('>>', reference('a'), reference('b')), code, test: true)
        code = '123 >> 456'
        assert_parses(bop('>>', number(123), number(456)), code, test: true)
        code = '123 >> 456 >> 789'
        assert_parses(
          bop('>>', bop('>>', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a << b'
        assert_parses(bop('<<', reference('a'), reference('b')), code, test: true)
        code = '123 << 456'
        assert_parses(bop('<<', number(123), number(456)), code, test: true)
        code = '123 << 456 << 789'
        assert_parses(
          bop('<<', bop('<<', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a & b'
        assert_parses(bop('&', reference('a'), reference('b')), code, test: true)
        code = '123 & 456'
        assert_parses(bop('&', number(123), number(456)), code, test: true)
        code = '123 & 456 & 789'
        assert_parses(
          bop('&', bop('&', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a | b'
        assert_parses(bop('|', reference('a'), reference('b')), code, test: true)
        code = '123 | 456'
        assert_parses(bop('|', number(123), number(456)), code, test: true)
        code = '123 | 456 | 789'
        assert_parses(
          bop('|', bop('|', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a ^ b'
        assert_parses(bop('^', reference('a'), reference('b')), code, test: true)
        code = '123 ^ 456'
        assert_parses(bop('^', number(123), number(456)), code, test: true)
        code = '123 ^ 456 ^ 789'
        assert_parses(
          bop('^', bop('^', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a ~^ b'
        assert_parses(bop('~^', reference('a'), reference('b')), code, test: true)
        code = '123 ~^ 456'
        assert_parses(bop('~^', number(123), number(456)), code, test: true)
        code = '123 ~^ 456 ~^ 789'
        assert_parses(
          bop('~^', bop('~^', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a ^~ b'
        assert_parses(bop('^~', reference('a'), reference('b')), code, test: true)
        code = '123 ^~ 456'
        assert_parses(bop('^~', number(123), number(456)), code, test: true)
        code = '123 ^~ 456 ^~ 789'
        assert_parses(
          bop('^~', bop('^~', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a * b'
        assert_parses(bop('*', reference('a'), reference('b')), code, test: true)
        code = '123 * 456'
        assert_parses(bop('*', number(123), number(456)), code, test: true)
        code = '123 * 456 * 789'
        assert_parses(
          bop('*', bop('*', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a / b'
        assert_parses(bop('/', reference('a'), reference('b')), code, test: true)
        code = '123 / 456'
        assert_parses(bop('/', number(123), number(456)), code, test: true)
        code = '123 / 456 / 789'
        assert_parses(
          bop('/', bop('/', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a % b'
        assert_parses(bop('%', reference('a'), reference('b')), code, test: true)
        code = '123 % 456'
        assert_parses(bop('%', number(123), number(456)), code, test: true)
        code = '123 % 456 % 789'
        assert_parses(
          bop('%', bop('%', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a + b'
        assert_parses(bop('+', reference('a'), reference('b')), code, test: true)
        code = '123 + 456'
        assert_parses(bop('+', number(123), number(456)), code, test: true)
        code = '123 + 456 + 789'
        assert_parses(
          bop('+', bop('+', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a - b'
        assert_parses(bop('-', reference('a'), reference('b')), code, test: true)
        code = '123 - 456'
        assert_parses(bop('-', number(123), number(456)), code, test: true)
        code = '123 - 456 - 789'
        assert_parses(
          bop('-', bop('-', number(123), number(456)), number(789)),
          code, test: true
        )

        code = 'a ** b'
        assert_parses(bop('**', reference('a'), reference('b')), code, test: true)
        code = '123 ** 456'
        assert_parses(bop('**', number(123), number(456)), code, test: true)
        code = '123 ** 456 ** 789'
        assert_parses(
          bop('**', bop('**', number(123), number(456)), number(789)),
          code, test: true
        )
      end

      def test_conditional_operation
        code = 'a ? b : c'
        assert_parses(
          cop(reference('a'), reference('b'), reference('c')),
          code, test: true
        )

        code = '1 ? 2 : 3'
        assert_parses(
          cop(number(1), number(2), number(3)),
          code, test: true
        )

        code = '1 ? 2 : 3 ? 4 : 5'
        assert_parses(
          cop(number(1), number(2), cop(number(3), number(4), number(5))),
          code, test: true
        )

        code = '1 ? 2 ? 3 : 4 : 5 ? 6 : 7'
        assert_parses(
          cop(
            number(1),
            cop(number(2), number(3), number(4)),
            cop(number(5), number(6), number(7))
          ),
          code, test: true
        )
      end

      def test_operator_precedence
        code = '+1**2'
        assert_parses(
          bop('**', uop('+', number(1)), number(2)),
          code, test: true
        )
        code = '+(1**2)'
        assert_parses(
          uop('+', bop('**', number(1), number(2))),
          code, test: true
        )

        code = '1*2**3'
        assert_parses(
          bop('*', number(1), bop('**', number(2), number(3))),
          code, test: true
        )
        code = '(1*2)**3'
        assert_parses(
          bop('**', bop('*', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1+2*3'
        assert_parses(
          bop('+', number(1), bop('*', number(2), number(3))),
          code, test: true
        )
        code = '(1+2)*3'
        assert_parses(
          bop('*', bop('+', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1<<2+3'
        assert_parses(
          bop('<<', number(1), bop('+', number(2), number(3))),
          code, test: true
        )
        code = '(1<<2)+3'
        assert_parses(
          bop('+', bop('<<', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1<2<<3'
        assert_parses(
          bop('<', number(1), bop('<<', number(2), number(3))),
          code, test: true
        )
        code = '(1<2)<<3'
        assert_parses(
          bop('<<', bop('<', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1==2<3'
        assert_parses(
          bop('==', number(1), bop('<', number(2), number(3))),
          code, test: true
        )
        code = '(1==2)<3'
        assert_parses(
          bop('<', bop('==', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1&2==3'
        assert_parses(
          bop('&', number(1), bop('==', number(2), number(3))),
          code, test: true
        )
        code = '(1&2)==3'
        assert_parses(
          bop('==', bop('&', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1^2&3'
        assert_parses(
          bop('^', number(1), bop('&', number(2), number(3))),
          code, test: true
        )
        code = '(1^2)&3'
        assert_parses(
          bop('&', bop('^', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1|2^3'
        assert_parses(
          bop('|', number(1), bop('^', number(2), number(3))),
          code, test: true
        )
        code = '(1|2)^3'
        assert_parses(
          bop('^', bop('|', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1&&2|3'
        assert_parses(
          bop('&&', number(1), bop('|', number(2), number(3))),
          code, test: true
        )
        code = '(1&&2)|3'
        assert_parses(
          bop('|', bop('&&', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1||2&&3'
        assert_parses(
          bop('||', number(1), bop('&&', number(2), number(3))),
          code, test: true
        )
        code = '(1||2)&&3'
        assert_parses(
          bop('&&', bop('||', number(1), number(2)), number(3)),
          code, test: true
        )

        code = '1||2?3:4'
        assert_parses(
          cop(bop('||', number(1), number(2)), number(3), number(4)),
          code, test: true
        )
        code = '1||(2?3:4)'
        assert_parses(
          bop('||', number(1), cop(number(2), number(3), number(4))),
          code, test: true
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
