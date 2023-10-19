# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  def upcase_randomly(string)
    upcase_pos =
      (0...string.size)
        .to_a
        .select { |i| /[a-z]/i =~ string[i] }
        .sample
    string
      .dup.tap { |s| s[upcase_pos] = s[upcase_pos].upcase }
  end

  describe 'boolean literal' do
    let(:parser) do
      SystemRDL::Parser.new(:boolean_literal)
    end

    it 'should be parsed by :boolean_literal parser' do
      expect(parser).to parse('true').as(boolean_literal(true))
      expect(parser).to parse('false').as(boolean_literal(false))
    end

    it 'should be case sensitive' do
      ['true', 'false'].each do |v|
        expect(parser).not_to parse(v.upcase)
        expect(parser).not_to parse(upcase_randomly(v))
      end
    end
  end

  describe 'number literal' do
    let(:parser) do
      SystemRDL::Parser.new(:number_literal)
    end

    it 'should be parsed by :number_literal parser' do
      expect(parser).to parse('0').as(number_literal(0))
      expect(parser).to parse('09').as(number_literal(9))
      expect(parser).to parse('40').as(number_literal(40))
      expect(parser).to parse('0x45').as(number_literal(0x45))
      expect(parser).to parse('0xab').as(number_literal(0xab))
      expect(parser).to parse('0XAB').as(number_literal(0xab))
      expect(parser).to parse('4\'d1').as(number_literal(1, width: 4))
      expect(parser).to parse('4\'D1').as(number_literal(1, width: 4))
      expect(parser).to parse('4\'d01').as(number_literal(1, width: 4))
      expect(parser).to parse('3\'b101').as(number_literal(0b101, width: 3))
      expect(parser).to parse('3\'B101').as(number_literal(0b101, width: 3))
      expect(parser).to parse('3\'b001').as(number_literal(0b001, width: 3))
      expect(parser).to parse('32\'hdeadbeaf').as(number_literal(0xdeadbeaf, width: 32))
      expect(parser).to parse('32\'HDEADBEAF').as(number_literal(0xdeadbeaf, width: 32))
      expect(parser).to parse('32\'h0000beaf').as(number_literal(0x0000beaf, width: 32))
    end

    specify 'number portion can contain multiple _ character at any position, expect the width and first position' do
      expect(parser).to parse('4_0').as(number_literal(40))
      expect(parser).not_to parse('_4')
      expect(parser).not_to parse('_40')
      expect(parser).to parse('0x4_5').as(number_literal(0x45))
      expect(parser).not_to parse('0x_45')
      expect(parser).not_to parse('0x_4')
      expect(parser).to parse('4\'d1_0').as(number_literal(10, width: 4))
      expect(parser).to parse('4\'d0_1').as(number_literal(1, width: 4))
      expect(parser).not_to parse('4\'d_10')
      expect(parser).not_to parse('4\'d_01')
      expect(parser).not_to parse('4\'d_1')
      expect(parser).not_to parse('1_0\'d10')
      expect(parser).to parse('3\'b1_01').as(number_literal(0b101, width: 3))
      expect(parser).to parse('3\'b1_0_1').as(number_literal(0b101, width: 3))
      expect(parser).not_to parse('3\'b_101')
      expect(parser).not_to parse('3\'b_1')
      expect(parser).not_to parse('1_0\'b101')
      expect(parser).to parse('32\'hde_ad_be_af').as(number_literal(0xdeadbeaf, width: 32))
      expect(parser).not_to parse('32\'h_de_ad_be_af')
      expect(parser).not_to parse('3_2\'hdeadbeaf')
    end

    specify 'verilog style number should have width portion' do
      expect(parser).not_to parse('\'d1')
      expect(parser).not_to parse('\'b101')
      expect(parser).not_to parse('\'hdeadbeaf')
    end
  end

  describe 'string literal' do
    let(:parser) do
      SystemRDL::Parser.new(:string_literal)
    end

    it 'should be parsed by :string_literal parser' do
      s = ''
      expect(parser).to parse("\"#{s}\"").as(string_literal(s))

      s = 'This is a string'
      expect(parser).to parse("\"#{s}\"").as(string_literal(s))

      s = "This is also \na string!"
      expect(parser).to parse("\"#{s}\"").as(string_literal(s))
    end

    specify 'double quote within a string should be escaped by \\' do
      s = 'This third string contains a \\"double quote\\"'
      expect(parser).to parse("\"#{s}\"").as(string_literal(s.tr('\\', '')))
    end
  end

  describe 'accesstype literal' do
    let(:parser) do
      SystemRDL::Parser.new(:accesstype_literal)
    end

    it 'should be parsed by :accesstype_literal' do
      expect(parser).to parse('na').as(accesstype_literal(:na))
      expect(parser).to parse('rw').as(accesstype_literal(:rw))
      expect(parser).to parse('wr').as(accesstype_literal(:wr))
      expect(parser).to parse('r').as(accesstype_literal(:r))
      expect(parser).to parse('w').as(accesstype_literal(:w))
      expect(parser).to parse('rw1').as(accesstype_literal(:rw1))
      expect(parser).to parse('w1').as(accesstype_literal(:w1))
    end

    it 'should be case sensitive' do
      ['na', 'rw', 'wr', 'r', 'w', 'rw1', 'w1'].each do |type|
        expect(parser).not_to parse(type.upcase)
        expect(parser).not_to parse(upcase_randomly(type))
      end
    end
  end

  describe 'onreadtype literal' do
    let(:parser) do
      SystemRDL::Parser.new(:onreadtype_literal)
    end

    it 'should be parsed by :onreadtype_literal parser' do
      expect(parser).to parse('rclr').as(onreadtype_literal(:rclr))
      expect(parser).to parse('rset').as(onreadtype_literal(:rset))
      expect(parser).to parse('ruser').as(onreadtype_literal(:ruser))
    end

    it 'should be case sensitive' do
      ['rclr', 'rset', 'ruser'].each do |type|
        expect(parser).not_to parse(type.upcase)
        expect(parser).not_to parse(upcase_randomly(type))
      end
    end
  end

  describe 'onwritetype literal' do
    let(:parser) do
      SystemRDL::Parser.new(:onwritetype_literal)
    end

    it 'should be parsed by :onwritetype_literal parser' do
      expect(parser).to parse('woset').as(onwritetype_literal(:woset))
      expect(parser).to parse('woclr').as(onwritetype_literal(:woclr))
      expect(parser).to parse('wot').as(onwritetype_literal(:wot))
      expect(parser).to parse('wzs').as(onwritetype_literal(:wzs))
      expect(parser).to parse('wzc').as(onwritetype_literal(:wzc))
      expect(parser).to parse('wzt').as(onwritetype_literal(:wzt))
      expect(parser).to parse('wclr').as(onwritetype_literal(:wclr))
      expect(parser).to parse('wset').as(onwritetype_literal(:wset))
      expect(parser).to parse('wuser').as(onwritetype_literal(:wuser))
    end

    it 'should be case sensitive' do
      ['woset', 'woclr', 'wot', 'wzs', 'wzc', 'wzt', 'wclr', 'wset', 'wuser'].each do |type|
        expect(parser).not_to parse(type.upcase)
        expect(parser).not_to parse(upcase_randomly(type))
      end
    end
  end

  describe 'addressingtype literal' do
    let(:parser) do
      SystemRDL::Parser.new(:addressingtype_literal)
    end

    it 'should be parsed by :addressingtype_literal parser' do
      expect(parser).to parse('compact').as(addressingtype_literal(:compact))
      expect(parser).to parse('regalign').as(addressingtype_literal(:regalign))
      expect(parser).to parse('fullalign').as(addressingtype_literal(:fullalign))
    end

    it 'should be case sensitive' do
      ['compact', 'regalign', 'fullalign'].each do |type|
        expect(parser).not_to parse(type.upcase)
        expect(parser).not_to parse(upcase_randomly(type))
      end
    end
  end

  describe 'precedencetype literal' do
    let(:parser) do
      SystemRDL::Parser.new(:precedencetype_literal)
    end

    it 'should be parsed by :precedencetype_literal parser' do
      expect(parser).to parse('hw').as(precedencetype_literal(:hw))
      expect(parser).to parse('sw').as(precedencetype_literal(:sw))
    end

    it 'should be case sensitive' do
      ['hw', 'sw'].each do |type|
        expect(parser).not_to parse(type.upcase)
        expect(parser).not_to parse(upcase_randomly(type))
      end
    end
  end
end
