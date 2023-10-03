# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  def join_elements(*elements)
    illegal_separators = [',', ':', ';', '/', '\\', ' ']
    elements.inject { |r, i| [r, i].join(illegal_separators.sample) }
  end

  describe 'instance_ref' do
    let(:parser) do
      SystemRDL::Parser.new(:instance_ref)
    end

    it 'should be parsed by :instance_ref parser' do
      expect(parser).to parse('a').as(reference('a'))
      expect(parser).to parse('regA.a').as(reference('regA', 'a'))
      expect(parser).to parse('regFA.regA.a').as(reference('regFA', 'regA', 'a'))
    end

    specify 'each instance references should be separated by dot' do
      expect(parser).not_to parse(join_elements('regA', 'a'))
      expect(parser).not_to parse(join_elements('regFA', 'regA', 'a'))
    end
  end

  describe 'property_ref' do
    let(:parser) do
      SystemRDL::Parser.new(:property_ref)
    end

    it 'should be parsed by :property_ref parser' do
      expect(parser).to parse('a->b').as(reference('a', property: 'b'))
      expect(parser).to parse('regA.a->b').as(reference('regA', 'a', property: 'b'))
      expect(parser).to parse('regFA.regA.a->b').as(reference('regFA', 'regA', 'a', property: 'b'))
    end

    specify 'each instance references should be separated by dot' do
      expect(parser).not_to parse(join_elements('regA', 'a->b'))
      expect(parser).not_to parse(join_elements('regFA', 'regA', 'a->b'))
    end

    specify 'instance references and property should be separated by \'->\'' do
      expect(parser).not_to parse('a<-b')
      expect(parser).not_to parse('a-<b')
      expect(parser).not_to parse('a>-b')
      expect(parser).not_to parse('a<<-b')
      expect(parser).not_to parse('a<--b')
      expect(parser).not_to parse('a< -b')
    end
  end
end
