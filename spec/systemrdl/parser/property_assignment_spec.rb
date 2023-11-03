# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:property_assignment)
  end

  describe 'explicit or default prop assignment' do
    it 'should be parsed by :property_assignment parser' do
      expect(parser).to parse('hw=w;')
        .as(property_assignment(reference(property: 'hw'), accesstype(:w)))
      expect(parser).to parse('default sw=rw;')
        .as(property_assignment(reference(property: 'sw'), accesstype(:rw), default: true))
      expect(parser).to parse('rclr = false;')
        .as(property_assignment(reference(property: 'rclr'), boolean(false)))
      expect(parser).to parse('rset;')
        .as(property_assignment(reference(property: 'rset')))
      expect(parser).to parse('default woclr;')
        .as(property_assignment(reference(property: 'woclr'), default: true))
      expect(parser).to parse('default woset = true;')
        .as(property_assignment(reference(property: 'woset'), boolean(true), default: true))

      expect(parser).to parse('name = "cplCode";')
        .as(property_assignment(reference(property: 'name'), string('cplCode')))
      expect(parser).to parse('default fieldwidth = 4;')
        .as(property_assignment(reference(property: 'fieldwidth'), number(4), default: true))

      expect(parser).to parse('encode = myBitFieldEncoding;')
        .as(property_assignment(reference(property: 'encode'), id('myBitFieldEncoding')))
      expect(parser).to parse('default encode=color;')
        .as(property_assignment(reference(property: 'encode'), id('color'), default: true))
    end
  end

  describe 'explicit or default prop modifier' do
    it 'should be parsed by :property_assignment parser' do
      expect(parser).to parse('posedge intr;')
        .as(property_modifier(reference(property: 'intr'), :posedge))
      expect(parser).to parse('default posedge intr;')
        .as(property_modifier(reference(property: 'intr'), :posedge, default: true))

      expect(parser).to parse('negedge intr;')
        .as(property_modifier(reference(property: 'intr'), :negedge))
      expect(parser).to parse('default negedge intr;')
        .as(property_modifier(reference(property: 'intr'), :negedge, default: true))

      expect(parser).to parse('bothedge intr;')
        .as(property_modifier(reference(property: 'intr'), :bothedge))
      expect(parser).to parse('default bothedge intr;')
        .as(property_modifier(reference(property: 'intr'), :bothedge, default: true))

      expect(parser).to parse('level intr;')
        .as(property_modifier(reference(property: 'intr'), :level))
      expect(parser).to parse('default level intr;')
        .as(property_modifier(reference(property: 'intr'), :level, default: true))

      expect(parser).to parse('nonsticky intr;')
        .as(property_modifier(reference(property: 'intr'), :nonsticky))
      expect(parser).to parse('default nonsticky intr;')
        .as(property_modifier(reference(property: 'intr'), :nonsticky, default: true))
    end
  end

  describe 'post prop assignment' do
    it 'should be parsed by :property_assignment parser' do
      expect(parser).to parse('a->hw=w;')
        .as(property_assignment(reference('a', property: 'hw'), accesstype(:w)))
      expect(parser).to parse('a->sw=rw;')
        .as(property_assignment(reference('a', property: 'sw'), accesstype(:rw)))
      expect(parser).to parse('a->rclr = false;')
        .as(property_assignment(reference('a', property: 'rclr'), boolean(false)))
      expect(parser).to parse('a->rset;')
        .as(property_assignment(reference('a', property: 'rset')))
      expect(parser).to parse('a->woclr;')
        .as(property_assignment(reference('a', property: 'woclr')))
      expect(parser).to parse('a->woset = true;')
        .as(property_assignment(reference('a', property: 'woset'), boolean(true)))

      expect(parser).to parse('a->name = "cplCode";')
        .as(property_assignment(reference('a', property: 'name'), string('cplCode')))
      expect(parser).to parse('a->fieldwidth = 4;')
        .as(property_assignment(reference('a', property: 'fieldwidth'), number(4)))

      expect(parser).to parse('a->encode = myBitFieldEncoding;')
        .as(property_assignment(reference('a', property: 'encode'), id('myBitFieldEncoding')))
      expect(parser).to parse('a->encode=color;')
        .as(property_assignment(reference('a', property: 'encode'), id('color')))
    end
  end
end
