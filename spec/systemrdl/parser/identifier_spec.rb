# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:id)
  end

  def identifer(id)
    proc do |result|
      result.is_a?(SystemRDL::AST::ID) && result.id == id
    end
  end

  describe 'simple identifer' do
    it 'should be parsed by :id parser' do
      id = 'my_identifier'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = 'My_IdEnTiFiEr'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = 'x'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '_y0123'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '_3'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '_'
      expect(parser).to parse(id, trace: true).as(&identifer(id))
    end

    specify 'keywords cannot be used as simple identifiers' do
      SystemRDL::Parser::KEYWORDS.each do |kw|
        expect(parser).not_to parse(kw, trace: true)
      end
    end

    specify 'reserved words cannot be used as simple identifiers' do
      SystemRDL::Parser::RESERVED_WORDS.each do |rw|
        expect(parser).not_to parse(rw, trace: true)
      end
    end
  end

  describe 'escaped identifier' do
    it 'should be parsed by :id parser' do
      id = '\my_identifier'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '\My_IdEnTiFiEr'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '\x'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '\_y0123'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '\_3'
      expect(parser).to parse(id, trace: true).as(&identifer(id))

      id = '\_'
      expect(parser).to parse(id, trace: true).as(&identifer(id))
    end

    specify 'keywords can be used as escaped identifiers' do
      SystemRDL::Parser::KEYWORDS.each do |kw|
        id = "\\#{kw}"
        expect(parser).to parse(id, trace: true).as(&identifer(id))
      end
    end

    specify 'reserved words cannot be used as escaped identifiers' do
      SystemRDL::Parser::RESERVED_WORDS.each do |rw|
        id = "\\#{rw}"
        expect(parser).to parse(id, trace: true).as(&identifer(id))
      end
    end
  end
end
