# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:component_definition)
  end

  describe 'field component' do
    it 'should be parsed by :component_definition parser' do
      expect(parser).to parse('field {} singlebitfield;')
        .as(field_difinition do |f|
          f.insts { |i| i.inst id: 'singlebitfield' }
        end)

      expect(parser).to parse('field {} somefield[4];')
        .as(field_difinition do |f|
          f.insts { |i| i.inst id: 'somefield', array: [4] }
        end)

      expect(parser).to parse('field {} somefield2[3:0];')
        .as(field_difinition do |f|
          f.insts { |i| i.inst id: 'somefield2', range: [3, 0] }
        end)

      expect(parser).to parse('field {} somefield4[0:31];')
        .as(field_difinition do |f|
          f.insts { |i| i.inst id: 'somefield4', range: [0, 31] }
        end)

      expect(parser).to parse('field f { sw = rw; hw = rw; };')
        .as(field_difinition('f') do |f|
          f.body property_assignment(id('sw'), accesstype(:rw))
          f.body property_assignment(id('hw'), accesstype(:rw))
        end)

      expect(parser).to parse('field { reset = 1\'b1; } a;')
        .as(field_difinition do |f|
          f.body property_assignment(id('reset'), number(1, width: 1))
          f.insts { |i| i.inst id: 'a' }
        end)

      expect(parser).to parse('field {} b=0;')
        .as(field_difinition do |f|
          f.insts { |i| i.inst id: 'b', assignment: [[:'=', 0]] }
        end)

      expect(parser).to parse('field { anded;} a[4]=0; ')
        .as(field_difinition do |f|
          f.body property_assignment(id('anded'))
          f.insts { |i| i.inst id: 'a', array: [4], assignment: [[:'=', 0]] }
        end)

      field = <<~'F'
        field {
          desc = "A Packet with a CRC Error has been received";
          level intr;
        } crc_error = 0x0;
      F
      expect(parser).to parse(field)
        .as(field_difinition do |f|
          f.body property_assignment(id('desc'), string('A Packet with a CRC Error has been received'))
          f.body property_modifier(id('intr'), :level)
          f.insts { |i| i.inst id: 'crc_error', assignment: [[:'=', 0]] }
        end)
    end
  end
end
