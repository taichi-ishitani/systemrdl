# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  let(:parser) do
    SystemRDL::Parser.new(:component_definition)
  end

  describe 'field component' do
    it 'should be parsed by :component_definition parser' do
      expect(parser).to parse('field {} singlebitfield;')
        .as(field_definition do |f|
          f.inst id: 'singlebitfield'
        end)

      expect(parser).to parse('field {} somefield[4];')
        .as(field_definition do |f|
          f.inst id: 'somefield', array: [4]
        end)

      expect(parser).to parse('field {} somefield2[3:0];')
        .as(field_definition do |f|
          f.inst id: 'somefield2', range: [3, 0]
        end)

      expect(parser).to parse('field {} somefield4[0:31];')
        .as(field_definition do |f|
          f.inst id: 'somefield4', range: [0, 31]
        end)

      expect(parser).to parse('field f { sw = rw; hw = rw; };')
        .as(field_definition('f') do |f|
          f.body property_assignment(id('sw'), accesstype(:rw))
          f.body property_assignment(id('hw'), accesstype(:rw))
        end)

      expect(parser).to parse('field { reset = 1\'b1; } a;')
        .as(field_definition do |f|
          f.body property_assignment(id('reset'), number(1, width: 1))
          f.inst id: 'a'
        end)

      expect(parser).to parse('field {} b=0;')
        .as(field_definition do |f|
          f.inst id: 'b', assignment: [[:'=', 0]]
        end)

      expect(parser).to parse('field { anded;} a[4]=0; ')
        .as(field_definition do |f|
          f.body property_assignment(id('anded'))
          f.inst id: 'a', array: [4], assignment: [[:'=', 0]]
        end)

      field = <<~'F'
        field {
          desc = "A Packet with a CRC Error has been received";
          level intr;
        } crc_error = 0x0;
      F
      expect(parser).to parse(field)
        .as(field_definition do |f|
          f.body property_assignment(id('desc'), string('A Packet with a CRC Error has been received'))
          f.body property_modifier(id('intr'), :level)
          f.inst id: 'crc_error', assignment: [[:'=', 0]]
        end)
    end
  end

  describe 'register component' do
    it 'should be parsed by :component_definition parser' do
      expect(parser).to parse('reg myReg { field {} data[31:0]; };')
        .as(register_definition('myReg') do |r|
          r.body field_definition { |f| f.inst id: 'data', range: [31, 0] }
        end)

      expect(parser).to parse('reg myReg {} reg_a[2], reg_b[2][4];')
        .as(register_definition('myReg') do |r|
          r.insts do |i|
            i.inst id: 'reg_a', array: [2]
            i.inst id: 'reg_b', array: [2, 4]
          end
        end)

      expect(parser).to parse('reg myReg {} reg_a @ 0x10;')
        .as(register_definition('myReg') do |r|
          r.inst id: 'reg_a', assignment: [[:'@', number(0x10)]]
        end)

      expect(parser).to parse('reg myReg {} reg_b[10] @0x100 += 0x10;')
        .as(register_definition('myReg') do |r|
          r.inst id: 'reg_b', array: [10], assignment: [[:'@', number(0x100)], [:'+=', number(0x10)]]
        end)

      expect(parser).to parse('reg myReg {} reg_a %= 0x10;')
        .as(register_definition('myReg') do |r|
          r.inst id: 'reg_a', assignment: [[:'%=', number(0x10)]]
        end)

      expect(parser).to parse('reg {} external reg_a , reg_b;')
        .as(register_definition do |r|
          r.insts do |i|
            i.external
            i.inst id: 'reg_a'
            i.inst id: 'reg_b'
          end
        end)

      reg = <<~'R'
        reg {
          field f_type {};
          f_type some_field;
        } some_reg;
      R
      expect(parser).to parse(reg)
        .as(register_definition do |r|
          r.body field_definition('f_type')
          r.body component_instances { |i| i.id 'f_type'; i.inst id: 'some_field' }
          r.inst id: 'some_reg'
        end)

      reg = <<~'R'
        reg {
          field {} f1;
          f1->name = "New name for Field 1";
        } some_reg;
      R
      expect(parser).to parse(reg)
        .as(register_definition do |r|
          r.body field_definition { |f| f.inst id: 'f1' }
          r.body property_assignment(reference(id('f1'), property: id('name')), string('New name for Field 1'))
          r.inst id: 'some_reg'
        end)

      reg = <<~'R'
        reg my32bitReg {
          regwidth = 32;
          accesswidth = 16;
          field {} a[16]=0;
          field {} b[16]=0;
        };
      R
      expect(parser).to parse(reg)
        .as(register_definition('my32bitReg') do |r|
          r.body property_assignment(id('regwidth'), number(32))
          r.body property_assignment(id('accesswidth'), number(16))
          r.body field_definition { |f| f.inst id: 'a', array: [16], assignment: [[:'=', 0]] }
          r.body field_definition { |f| f.inst id: 'b', array: [16], assignment: [[:'=', 0]] }
        end)
    end
  end

  describe 'memory component' do
    it 'should be parsed by :component_definition parser' do
      memory = <<~'M'
        mem fifo_mem {
          mementries = 1024;
          memwidth = 32;
        };
      M
      expect(parser).to parse(memory)
        .as(memory_definition('fifo_mem') do |m|
          m.body property_assignment(id('mementries'), number(1024))
          m.body property_assignment(id('memwidth'), number(32))
        end)

      memory = <<~'M'
        external mem fifo_mem {
          mementries = 1024;
          memwidth = 32;
        } mem_a, mem_b;
      M
      expect(parser).to parse(memory)
        .as(memory_definition('fifo_mem') do |m|
          m.body property_assignment(id('mementries'), number(1024))
          m.body property_assignment(id('memwidth'), number(32))
          m.insts do |i|
            i.external
            i.inst id: 'mem_a'
            i.inst id: 'mem_b'
          end
        end)

      memory = <<~'M'
        mem {
          mementries = 1024;
          memwidth = 32;
        } external mem_a, mem_b;
      M
      expect(parser).to parse(memory)
        .as(memory_definition do |m|
          m.body property_assignment(id('mementries'), number(1024))
          m.body property_assignment(id('memwidth'), number(32))
          m.insts do |i|
            i.external
            i.inst id: 'mem_a'
            i.inst id: 'mem_b'
          end
        end)
    end
  end
end