# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:id)
  end

  describe 'simple identifer' do
    it 'should be parsed by :id parser' do
      id = 'my_identifier'
      expect(parser).to parse(id).as(identifer(id))

      id = 'My_IdEnTiFiEr'
      expect(parser).to parse(id).as(identifer(id))

      id = 'x'
      expect(parser).to parse(id).as(identifer(id))

      id = '_y0123'
      expect(parser).to parse(id).as(identifer(id))

      id = '_3'
      expect(parser).to parse(id).as(identifer(id))

      id = '_'
      expect(parser).to parse(id).as(identifer(id))
    end

    specify 'keywords cannot be used as simple identifiers' do
      SystemRDL::Parser::KEYWORDS.each do |kw|
        expect(parser).not_to parse(kw)
      end
    end

    specify 'reserved words cannot be used as simple identifiers' do
      SystemRDL::Parser::RESERVED_WORDS.each do |rw|
        expect(parser).not_to parse(rw)
      end
    end
  end

  describe 'escaped identifier' do
    it 'should be parsed by :id parser' do
      id = '\my_identifier'
      expect(parser).to parse(id).as(identifer(id))

      id = '\My_IdEnTiFiEr'
      expect(parser).to parse(id).as(identifer(id))

      id = '\x'
      expect(parser).to parse(id).as(identifer(id))

      id = '\_y0123'
      expect(parser).to parse(id).as(identifer(id))

      id = '\_3'
      expect(parser).to parse(id).as(identifer(id))

      id = '\_'
      expect(parser).to parse(id).as(identifer(id))
    end

    specify 'keywords can be used as escaped identifiers' do
      SystemRDL::Parser::KEYWORDS.each do |kw|
        id = "\\#{kw}"
        expect(parser).to parse(id).as(identifer(id))
      end
    end

    specify 'reserved words cannot be used as escaped identifiers' do
      SystemRDL::Parser::RESERVED_WORDS.each do |rw|
        id = "\\#{rw}"
        expect(parser).to parse(id).as(identifer(id))
      end
    end
  end

  describe 'this keyword' do
    let(:parser) do
      SystemRDL::Parser.new(:this_keyword)
    end

    it 'should be parsed by :this_keyword parser' do
      expect(parser).to parse('this').as(this_keyword)
    end
  end
end
