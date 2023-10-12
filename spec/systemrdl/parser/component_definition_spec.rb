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

  describe 'register file component' do
    it 'should be parsed by :component_definition parser' do
      register_file = <<~'RF'
        regfile fifo_rfile {
          alignment = 8;
          reg {field {} a;} a;
          reg {field {} a;} b;
        };
      RF
      expect(parser).to parse(register_file)
        .as(register_file_definition('fifo_rfile') do |rf|
          rf.body property_assignment(id('alignment'), number(8))
          rf.body(register_definition do |r|
            r.body field_definition { |f| f.inst id: 'a' }
            r.inst id: 'a'
          end)
          rf.body(register_definition do |r|
            r.body field_definition { |f| f.inst id: 'a' }
            r.inst id: 'b'
          end)
        end)

      register_file = <<~'RF'
        regfile {
          external fifo_rfile fifo_a;
          external fifo_rfile fifo_b[64];
          sharedextbus;
        } top_regfile;
      RF
      expect(parser).to parse(register_file)
        .as(register_file_definition do |rf|
          rf.body component_instances { |i| i.external; i.id 'fifo_rfile'; i.inst id: 'fifo_a' }
          rf.body component_instances { |i| i.external; i.id 'fifo_rfile'; i.inst id: 'fifo_b', array: [64] }
          rf.body property_assignment(id('sharedextbus'))
          rf.inst id: 'top_regfile'
        end)
    end
  end

  describe 'address map component' do
    it 'should be parsed by :component_definition parser' do
      address_map = <<~'AM'
        addrmap some_bridge {
          desc="overlapping address maps with both shared register space and orthogonal register space";
          bridge;
          reg status {
            shared;
            field {
              hw=rw;
              sw=r;
            } stat1 = 1'b0;
          };
          reg some_axi_reg {
            field {
              desc="credits on the AXI interface";
            } credits[4] = 4'h7;
          };
          reg some_ahb_reg {
            field {
              desc="credits on the AHB Interface";
            } credits[8] = 8'b00000011;
          };

          addrmap {
            littleendian;
            some_ahb_reg ahb_credits;
            status ahb_stat @0x20;
            ahb_stat.stat1->desc = "bar";
          } ahb;
        };
      AM
      expect(parser).to parse(address_map)
        .as(address_map_definition('some_bridge') do |am|
          am.body property_assignment(id('desc'), string('overlapping address maps with both shared register space and orthogonal register space'))
          am.body property_assignment(id('bridge'))
          am.body register_definition('status') { |r|
            r.body property_assignment(id('shared'))
            r.body field_definition { |f|
              f.body property_assignment(id('hw'), accesstype(:rw))
              f.body property_assignment(id('sw'), accesstype(:r))
              f.inst id: 'stat1', assignment: [[:'=', number(0, width: 1)]]
            }
          }
          am.body register_definition('some_axi_reg') { |r|
            r.body field_definition { |f|
              f.body property_assignment(id('desc'), string('credits on the AXI interface'))
              f.inst id: 'credits', array: [4], assignment: [[:'=', number(7, width: 4)]]
            }
          }
          am.body register_definition('some_ahb_reg') { |r|
            r.body field_definition { |f|
              f.body property_assignment(id('desc'), string('credits on the AHB Interface'))
              f.inst id: 'credits', array: [8], assignment: [[:'=', number(3, width: 8)]]
            }
          }

          am.body address_map_definition { |am_ahb|
            am_ahb.body property_assignment(id('littleendian'))
            am_ahb.body component_instances { |i| i.id 'some_ahb_reg'; i.inst id: 'ahb_credits' }
            am_ahb.body component_instances { |i| i.id 'status'; i.inst id: 'ahb_stat', assignment: [[:'@', number(0x20)]] }
            am_ahb.body property_assignment(reference('ahb_stat', 'stat1', property: 'desc'), string('bar'))
            am_ahb.inst id: 'ahb'
          }
        end)
    end
  end

  describe 'component parameters' do
    specify 'definitive component types may be parameterized' do
      reg = <<~'REG'
        reg myReg #(
          longint unsigned  SIZE  = 32
        ) {
          regwidth = SIZE;
          field {} data[SIZE-1];
        };
      REG
      expect(parser).to parse(reg)
        .as(register_definition('myReg') do |r|
          r.paraemter_definition id: 'SIZE', data_type: :longint, default: number(32)
          r.body property_assignment(id('regwidth'), reference('SIZE'))
          r.body field_definition { |f| f.inst id: 'data', array: [b_op(:'-', reference('SIZE'), number(1))]}
        end)

      reg = <<~'REG'
        reg myReg #(
          longint unsigned  SIZE    = 32,
          boolean           SHARED
        ) {
          regwidth = SIZE;
          shared = SHARED;
          field {} data[SIZE-1];
        };
      REG
      expect(parser).to parse(reg)
        .as(register_definition('myReg') do |r|
          r.paraemter_definition id: 'SIZE', data_type: :longint, default: number(32)
          r.paraemter_definition id: 'SHARED', data_type: :boolean
          r.body property_assignment(id('regwidth'), reference('SIZE'))
          r.body property_assignment(id('shared'), reference('SHARED'))
          r.body field_definition { |f| f.inst id: 'data', array: [b_op(:'-', reference('SIZE'), number(1))]}
        end)

      address_map = <<~'AM'
        addrmap myAmap {
          myReg #(.SIZE(16)) reg16;
          myReg #(.SIZE(8), .SHARED(false)) reg8;
        };
      AM
      expect(parser).to parse(address_map)
        .as(address_map_definition('myAmap') do |am|
          am.body component_instances { |i|
            i.id 'myReg'
            i.parameter_assignment id: 'SIZE', value: number(16)
            i.inst id: 'reg16'
          }
          am.body component_instances { |i|
            i.id 'myReg'
            i.parameter_assignment id: 'SIZE', value: number(8)
            i.parameter_assignment id: 'SHARED', value: boolean(false)
            i.inst id: 'reg8'
          }
        end)
    end

    specify 'anonymous component types cannt be parameterized' do
      reg = <<~'REG'
        reg #(
          longint unsigned  SIZE  = 32
        ) {
        } reg_a;
      REG
      expect(parser).not_to parse(reg)
    end

    specify 'empty parameter lists are not allowed' do
      reg = <<~'REG'
        reg myReg #() {
        };
      REG
      expect(parser).not_to parse(reg)

      address_map = <<~'AM'
        addrmap myAmap {
          myReg #() reg_a;
        };
      AM
      expect(parser).not_to parse(address_map)
    end
  end
end
