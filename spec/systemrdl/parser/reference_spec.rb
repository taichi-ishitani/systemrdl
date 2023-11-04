# frozen_string_literal: true

RSpec.describe SystemRDL::Parser, :parser do
  def join_elements(*elements)
    illegal_separators = [',', ':', ';', '/', '\\', ' ']
    elements.inject { |r, i| [r, i].join(illegal_separators.sample) }
  end

  describe 'instance_ref' do
    let(:parser) do
      SystemRDL::Parser.new(:instance_ref)
    end

    it 'should be parsed by :instance_ref parser' do
      expect(parser).to parse('a')
        .as(reference('a'))
      expect(parser).to parse('a[0]')
        .as(reference(['a', number(0)]))
      expect(parser).to parse('a[0][1]')
        .as(reference(['a', number(0), number(1)]))

      expect(parser).to parse('regA.a')
        .as(reference('regA', 'a'))
      expect(parser).to parse('regA[0].a[1]')
        .as(reference(['regA', number(0)], ['a', number(1)]))
      expect(parser).to parse('regA[0][1].a[2][3]')
        .as(reference(['regA', number(0), number(1)], ['a', number(2), number(3)]))

      expect(parser).to parse('regFA.regA.a')
        .as(reference('regFA', 'regA', 'a'))
      expect(parser).to parse('regFA[0].regA[1].a[2]')
        .as(reference(['regFA', number(0)], ['regA', number(1)], ['a', number(2)]))
      expect(parser).to parse('regFA[0][1].regA[2][3].a[4][5]')
        .as(reference(['regFA', number(0), number(1)], ['regA', number(2), number(3)], ['a', number(4), number(5)]))
    end

    specify 'each instance references should be separated by dot' do
      expect(parser).not_to parse(join_elements('regA', 'a'))
      expect(parser).not_to parse(join_elements('regA[0]', 'a[1]'))
      expect(parser).not_to parse(join_elements('regFA', 'regA', 'a'))
      expect(parser).not_to parse(join_elements('regFA[0]', 'regA[1]', 'a[2]'))
    end
  end

  describe 'property_ref' do
    let(:parser) do
      SystemRDL::Parser.new(:property_ref)
    end

    it 'should be parsed by :property_ref parser' do
      expect(parser).to parse('a->b')
        .as(reference('a', property: 'b'))
      expect(parser).to parse('a[0]->b')
        .as(reference(['a', number(0)], property: 'b'))
      expect(parser).to parse('a[0][1]->b')
        .as(reference(['a', number(0), number(1)], property: 'b'))

      expect(parser).to parse('regA.a->b')
        .as(reference('regA', 'a', property: 'b'))
      expect(parser).to parse('regA[0].a[1]->b')
        .as(reference(['regA', number(0)], ['a', number(1)], property: 'b'))
      expect(parser).to parse('regA[0][1].a[2][3]->b')
        .as(reference(['regA', number(0), number(1)], ['a', number(2), number(3)], property: 'b'))

      expect(parser).to parse('regFA.regA.a->b')
        .as(reference('regFA', 'regA', 'a', property: 'b'))
      expect(parser).to parse('regFA[0].regA[1].a[2]->b')
        .as(reference(['regFA', number(0)], ['regA', number(1)], ['a', number(2)], property: 'b'))
      expect(parser).to parse('regFA[0][1].regA[2][3].a[4][5]->b')
        .as(reference(['regFA', number(0), number(1)], ['regA', number(2), number(3)], ['a', number(4), number(5)], property: 'b'))
    end

    specify 'each instance references should be separated by dot' do
      expect(parser).not_to parse(join_elements('regA', 'a->b'))
      expect(parser).not_to parse(join_elements('regA[0]', 'a[1]->b'))
      expect(parser).not_to parse(join_elements('regFA', 'regA', 'a->b'))
      expect(parser).not_to parse(join_elements('regFA[0]', 'regA[1]', 'a[2]->b'))
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
