# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:constant_expression)
  end

  describe 'constant primary' do
    specify 'a number literal should be treated as a constant expression' do
      expect(parser).to parse('123').as(number(123))
      expect(parser).to parse('0xabcd').as(number(0xabcd))
      expect(parser).to parse("4'b1010").as(number(0b1010, width: 4))
      expect(parser).to parse("7'd123").as(number(123, width: 7))
      expect(parser).to parse("16'habcd").as(number(0xabcd, width: 16))
    end

    specify 'stparserring literals should be treated as constant expressions' do
      expect(parser).to parse('"this is a test."').as(string('this is a test.'))
    end

    specify 'boolean literals should be treated as constant expressions' do
      expect(parser).to parse('true').as(boolean(true))
      expect(parser).to parse('false').as(boolean(false))
    end

    specify 'accesstype literals should be treated as constant expressions' do
      ['na', 'rw', 'wr', 'r', 'w', 'rw1', 'w1'].each do |accesstype|
        expect(parser).to parse(accesstype).as(accesstype(accesstype.to_sym))
      end
    end

    specify 'onreadtype literals should be treated as constant expressions' do
      ['rclr', 'rset', 'ruser'].each do |onreadtype|
        expect(parser).to parse(onreadtype).as(onreadtype(onreadtype.to_sym))
      end
    end

    specify 'onwritetype literals should be treated as constant expressions' do
      ['woset', 'woclr', 'wot', 'wzs', 'wzc', 'wzt', 'wclr', 'wset', 'wuser'].each do |onwritetype|
        expect(parser).to parse(onwritetype).as(onwritetype(onwritetype.to_sym))
      end
    end

    specify 'addressingtype literals should be treated as constant expressions' do
      ['compact', 'regalign', 'fullalign'].each do |addressingtype|
        expect(parser).to parse(addressingtype).as(addressingtype(addressingtype.to_sym))
      end
    end

    specify "'this' keyword should be treated as a constant expression" do
      expect(parser).to parse('this').as(this_keyword)
    end

    specify 'instance_ref should be treated as a constant expression' do
      expect(parser).to parse('a').as(reference('a'))
      expect(parser).to parse('RegA.a').as(reference('RegA', 'a'))
    end

    specify 'property_ref should be treated as a constant expression' do
      expect(parser).to parse('a->b').as(reference('a', property: 'b'))
      expect(parser).to parse('RegA.a->b').as(reference('RegA', 'a', property: 'b'))
    end
  end

  describe 'constant cast' do
    it 'should be parsed by :constant_expression parser' do
      expect(parser).to parse('boolean\'(1+2)')
        .as(cast(data_type(:boolean), b_op(:'+', number(1), number(2))))
      expect(parser).to parse('bit\'(1+2)')
        .as(cast(data_type(:bit), b_op(:'+', number(1), number(2))))
      expect(parser).to parse('longint\'(1+2)')
        .as(cast(data_type(:longint), b_op(:'+', number(1), number(2))))
      expect(parser).to parse('17\'(1+2)')
        .as(cast(number(17), b_op(:'+', number(1), number(2))))
      expect(parser).to parse('(10+7)\'(1+2)')
        .as(cast(b_op(:'+', number(10), number(7)), b_op(:'+', number(1), number(2))))
      expect(parser).to parse('17\'(1+2)\'(1+2)')
        .as(cast(number(17), cast(b_op(:'+', number(1), number(2)), b_op(:'+', number(1), number(2)))))
      expect(parser).to parse('longint\'(1+2)\'(1+2)')
        .as(cast(data_type(:longint), cast(b_op(:'+', number(1), number(2)), b_op(:'+', number(1), number(2)))))
      expect(parser).to parse('longint\'bit\'boolean\'(1+2)')
        .as(cast(data_type(:longint), cast(data_type(:bit), cast(data_type(:boolean), b_op(:'+', number(1), number(2))))))
    end
  end

  describe 'unary operations' do
    it 'should be parsed by :constant_expression parser' do
      expect(parser).to parse('!a').as(u_op(:'!', reference('a')))
      expect(parser).to parse('!true').as(u_op(:'!', boolean(true)))

      expect(parser).to parse('+a').as(u_op(:'+', reference('a')))
      expect(parser).to parse("+8'hab").as(u_op(:'+', number(0xab, width: 8)))

      expect(parser).to parse('-a').as(u_op(:'-', reference('a')))
      expect(parser).to parse("-8'hab").as(u_op(:'-', number(0xab, width: 8)))

      expect(parser).to parse('~a').as(u_op(:'~', reference('a')))
      expect(parser).to parse("~8'hab").as(u_op(:'~', number(0xab, width: 8)))

      expect(parser).to parse('&a').as(u_op(:'&', reference('a')))
      expect(parser).to parse("&8'hab").as(u_op(:'&', number(0xab, width: 8)))

      expect(parser).to parse('~&a').as(u_op(:'~&', reference('a')))
      expect(parser).to parse("~&8'hab").as(u_op(:'~&', number(0xab, width: 8)))

      expect(parser).to parse('|a').as(u_op(:'|', reference('a')))
      expect(parser).to parse("|8'hab").as(u_op(:'|', number(0xab, width: 8)))

      expect(parser).to parse('~|a').as(u_op(:'~|', reference('a')))
      expect(parser).to parse("~|8'hab").as(u_op(:'~|', number(0xab, width: 8)))

      expect(parser).to parse('^a').as(u_op(:'^', reference('a')))
      expect(parser).to parse("^8'hab").as(u_op(:'^', number(0xab, width: 8)))

      expect(parser).to parse('~^a').as(u_op(:'~^', reference('a')))
      expect(parser).to parse("~^8'hab").as(u_op(:'~^', number(0xab, width: 8)))

      expect(parser).to parse('^~a').as(u_op(:'^~', reference('a')))
      expect(parser).to parse("^~8'hab").as(u_op(:'^~', number(0xab, width: 8)))
    end
  end

  describe 'binary operation' do
    it 'should be parsed by :constant_expression parser' do
      expect(parser).to parse('a && b')
        .as(b_op(:'&&', reference('a'), reference('b')))
      expect(parser).to parse('true && true')
        .as(b_op(:'&&', boolean(true), boolean(true)))
      expect(parser).to parse('true && true && false')
        .as(b_op(:'&&', b_op(:'&&', boolean(true), boolean(true)), boolean(false)))

      expect(parser).to parse('a || b')
        .as(b_op(:'||', reference('a'), reference('b')))
      expect(parser).to parse('true || true')
        .as(b_op(:'||', boolean(true), boolean(true)))
      expect(parser).to parse('true || true || false')
        .as(b_op(:'||', b_op(:'||', boolean(true), boolean(true)), boolean(false)))

      expect(parser).to parse('a < b')
        .as(b_op(:'<', reference('a'), reference('b')))
      expect(parser).to parse('123 < 456')
        .as(b_op(:'<', number(123), number(456)))
      expect(parser).to parse('123 < 456 < 789')
        .as(b_op(:'<', b_op(:'<', number(123), number(456)), number(789)))

      expect(parser).to parse('a > b')
        .as(b_op(:'>', reference('a'), reference('b')))
      expect(parser).to parse('123 > 456')
        .as(b_op(:'>', number(123), number(456)))
      expect(parser).to parse('123 > 456 > 789')
        .as(b_op(:'>', b_op(:'>', number(123), number(456)), number(789)))

      expect(parser).to parse('a <= b')
        .as(b_op(:'<=', reference('a'), reference('b')))
      expect(parser).to parse('123 <= 456')
        .as(b_op(:'<=', number(123), number(456)))
      expect(parser).to parse('123 <= 456 <= 789')
        .as(b_op(:'<=', b_op(:'<=', number(123), number(456)), number(789)))

      expect(parser).to parse('a >= b')
        .as(b_op(:'>=', reference('a'), reference('b')))
      expect(parser).to parse('123 >= 456')
        .as(b_op(:'>=', number(123), number(456)))
      expect(parser).to parse('123 >= 456 >= 789')
        .as(b_op(:'>=', b_op(:'>=', number(123), number(456)), number(789)))

      expect(parser).to parse('a == b')
        .as(b_op(:'==', reference('a'), reference('b')))
      expect(parser).to parse('123 == 456')
        .as(b_op(:'==', number(123), number(456)))
      expect(parser).to parse('123 < 456 < 789')
        .as(b_op(:'<', b_op(:'<', number(123), number(456)), number(789)))

      expect(parser).to parse('a != b')
        .as(b_op(:'!=', reference('a'), reference('b')))
      expect(parser).to parse('123 != 456')
        .as(b_op(:'!=', number(123), number(456)))
      expect(parser).to parse('123 != 456 != 789')
        .as(b_op(:'!=', b_op(:'!=', number(123), number(456)), number(789)))

      expect(parser).to parse('a >> b')
        .as(b_op(:'>>', reference('a'), reference('b')))
      expect(parser).to parse('123 >> 1')
        .as(b_op(:'>>', number(123), number(1)))
      expect(parser).to parse('123 >> 1 >> 0')
        .as(b_op(:>>, b_op(:'>>', number(123), number(1)), number(0)))

      expect(parser).to parse('a << b')
        .as(b_op(:'<<', reference('a'), reference('b')))
      expect(parser).to parse('123 << 1')
        .as(b_op(:'<<', number(123), number(1)))
      expect(parser).to parse('123 << 1 << 0')
        .as(b_op(:<<, b_op(:'<<', number(123), number(1)), number(0)))

      expect(parser).to parse('a & b')
        .as(b_op(:'&', reference('a'), reference('b')))
      expect(parser).to parse("8'hab & 8'h11")
        .as(b_op(:'&', number(0xab, width: 8), number(0x11, width: 8)))
      expect(parser).to parse("8'hab & 8'h11 & 8'h22")
        .as(b_op(:'&', b_op(:'&', number(0xab, width: 8), number(0x11, width: 8)), number(0x22, width: 8)))

      expect(parser).to parse('a| b')
        .as(b_op(:'|', reference('a'), reference('b')))
      expect(parser).to parse("8'hab | 8'h11")
        .as (b_op(:'|', number(0xab, width: 8), number(0x11, width: 8)))
      expect(parser).to parse("8'hab | 8'h11 | 8'h22")
        .as(b_op(:'|', b_op(:'|', number(0xab, width: 8), number(0x11, width: 8)), number(0x22, width: 8)))

      expect(parser).to parse('a ^ b')
        .as(b_op(:'^', reference('a'), reference('b')))
      expect(parser).to parse("8'hab ^ 8'h11")
        .as(b_op(:'^', number(0xab, width: 8), number(0x11, width: 8)))
      expect(parser).to parse("8'hab ^ 8'h11 ^ 8'h22")
        .as(b_op(:'^', b_op(:'^', number(0xab, width: 8), number(0x11, width: 8)), number(0x22, width: 8)))

      expect(parser).to parse('a ~^ b')
        .as(b_op(:'~^', reference('a'), reference('b')))
      expect(parser).to parse("8'hab ~^ 8'h11")
        .as(b_op(:'~^', number(0xab, width: 8), number(0x11, width: 8)))
      expect(parser).to parse("8'hab ~^ 8'h11 ~^ 8'h22")
        .as(b_op(:'~^', b_op(:'~^', number(0xab, width: 8), number(0x11, width: 8)), number(0x22, width: 8)))

      expect(parser).to parse('a ^~ b')
        .as(b_op(:'^~', reference('a'), reference('b')))
      expect(parser).to parse("8'hab ^~ 8'h11")
        .as(b_op(:'^~', number(0xab, width: 8), number(0x11, width: 8)))
      expect(parser).to parse("8'hab ^~ 8'h11 ^~ 8'h22")
        .as(b_op(:'^~', b_op(:'^~', number(0xab, width: 8), number(0x11, width: 8)), number(0x22, width: 8)))

      expect(parser).to parse('a * b')
        .as(b_op(:'*', reference('a'), reference('b')))
      expect(parser).to parse('123 * 456')
        .as(b_op(:'*', number(123), number(456)))
      expect(parser).to parse('123 * 456 * 789')
        .as(b_op(:'*', b_op(:'*', number(123), number(456)), number(789)))

      expect(parser).to parse('a / b')
        .as(b_op(:'/', reference('a'), reference('b')))
      expect(parser).to parse('123 / 456')
        .as(b_op(:'/', number(123), number(456)))
      expect(parser).to parse('123 / 456 / 789')
        .as(b_op(:'/', b_op(:'/', number(123), number(456)), number(789)))

      expect(parser).to parse('a % b')
        .as(b_op(:'%', reference('a'), reference('b')))
      expect(parser).to parse('123 % 456')
        .as(b_op(:'%', number(123), number(456)))
      expect(parser).to parse('123 % 456 % 789')
        .as(b_op(:'%', b_op(:'%', number(123), number(456)), number(789)))

      expect(parser).to parse('a+ b')
        .as(b_op(:'+', reference('a'), reference('b')))
      expect(parser).to parse('123 + 456')
        .as(b_op(:'+', number(123), number(456)))
      expect(parser).to parse('123 + 456 + 789')
        .as(b_op(:'+', b_op(:'+', number(123), number(456)), number(789)))

      expect(parser).to parse('a - b')
        .as(b_op(:'-', reference('a'), reference('b')))
      expect(parser).to parse('123 - 456')
        .as(b_op(:'-', number(123), number(456)))
      expect(parser).to parse('123 - 456 - 789')
        .as(b_op(:'-', b_op(:'-', number(123), number(456)), number(789)))

      expect(parser).to parse('a ** b')
        .as(b_op(:'**', reference('a'), reference('b')))
      expect(parser).to parse('123 ** 456')
        .as(b_op(:'**', number(123), number(456)))
      expect(parser).to parse('123 ** 456 ** 789')
        .as(b_op(:'**', b_op(:'**', number(123), number(456)), number(789)))
    end
  end

  describe 'conditional operation' do
    it 'should be parsed by :constant_expression parser' do
      expect(parser).to parse('a ? b : c')
        .as(c_op(reference('a'), reference('b'), reference('c')))
      expect(parser).to parse('1 ? 2 : 3')
        .as(c_op(number(1), number(2), number(3)))
      expect(parser).to parse('1 ? 2 : 3 ? 4 : 5')
        .as(c_op(number(1), number(2), c_op(number(3), number(4), number(5))))
      expect(parser).to parse('1 ? 2 ? 3 : 4 : 5 ? 6 : 7')
        .as(c_op(number(1), c_op(number(2), number(3), number(4)), c_op(number(5), number(6), number(7))))
    end
  end

  specify 'oparator precedence is listed in Table 11-2 on IEEE1800-2012' do
    expect(parser).to parse('+1**2')
      .as(b_op(:'**', u_op(:'+', number(1)), number(2)))
    expect(parser).to parse('+(1**2)')
      .as(u_op(:'+', b_op(:'**', number(1), number(2))))
    expect(parser).to parse('1*2**3')
      .as(b_op(:'*', number(1), b_op(:'**', number(2), number(3))))
    expect(parser).to parse('(1*2)**3')
      .as(b_op(:'**', b_op(:'*', number(1), number(2)), number(3)))
    expect(parser).to parse('1+2*3')
      .as(b_op(:'+', number(1), b_op(:'*', number(2), number(3))))
    expect(parser).to parse('(1+2)*3')
      .as(b_op(:'*', b_op(:'+', number(1), number(2)), number(3)))
    expect(parser).to parse('1<<2+3')
      .as(b_op(:'<<', number(1), b_op(:'+', number(2), number(3))))
    expect(parser).to parse('(1<<2)+3')
      .as(b_op(:'+', b_op(:'<<', number(1), number(2)), number(3)))
    expect(parser).to parse('1<2<<3')
      .as(b_op(:'<', number(1), b_op(:'<<', number(2), number(3))))
    expect(parser).to parse('(1<2)<<3')
      .as(b_op(:'<<', b_op(:'<', number(1), number(2)), number(3)))
    expect(parser).to parse('1==2<3')
      .as(b_op(:'==', number(1), b_op(:'<', number(2), number(3))))
    expect(parser).to parse('(1==2)<3')
      .as(b_op(:'<', b_op(:'==', number(1), number(2)), number(3)))
    expect(parser).to parse('1&2==3')
      .as(b_op(:'&', number(1), b_op(:'==', number(2), number(3))))
    expect(parser).to parse('(1&2)==3')
      .as(b_op(:'==', b_op(:'&', number(1), number(2)), number(3)))
    expect(parser).to parse('1^2&3')
      .as(b_op(:'^', number(1), b_op(:'&', number(2), number(3))))
    expect(parser).to parse('(1^2)&3')
      .as(b_op(:'&', b_op(:'^', number(1), number(2)), number(3)))
    expect(parser).to parse('1|2^3')
      .as(b_op(:'|', number(1), b_op(:'^', number(2), number(3))))
    expect(parser).to parse('(1|2)^3')
      .as(b_op(:'^', b_op(:'|', number(1), number(2)), number(3)))
    expect(parser).to parse('1&&2|3')
      .as(b_op(:'&&', number(1), b_op(:'|', number(2), number(3))))
    expect(parser).to parse('(1&&2)|3')
      .as(b_op(:'|', b_op(:'&&', number(1), number(2)), number(3)))
    expect(parser).to parse('1||2&&3')
      .as(b_op(:'||', number(1), b_op(:'&&', number(2), number(3))))
    expect(parser).to parse('(1||2)&&3')
      .as(b_op(:'&&', b_op(:'||', number(1), number(2)), number(3)))
    expect(parser).to parse('1||2?3:4')
      .as(c_op(b_op(:'||', number(1), number(2)), number(3), number(4)))
    expect(parser).to parse('1||(2?3:4)')
      .as(b_op(:'||', number(1), c_op(number(2), number(3), number(4))))
  end
end
