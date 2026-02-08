# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestComponentDefinition < TestCase
      def test_field_component
        code = 'field {} singlebitfield;'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:singlebitfield))
          ),
          code
        )

        code = 'field {} somefield[4];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, array(4)))
          ),
          code
        )

        code = 'field {} somefield[3:0];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, range(3, 0)))
          ),
          code
        )

        code = 'field {} somefield[0:31];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, range(0, 31)))
          ),
          code
        )

        code = 'field f { sw = rw; hw = rw; };'
        assert_parses(
          field_named_definition(
            id(:f),
            prop_assignment(:sw, access_type(:rw)),
            prop_assignment(:hw, access_type(:rw))
          ),
          code
        )

        code = "field { reset = 1'b1; } a;"
        assert_parses(
          field_anonymous_definition(
            prop_assignment(:reset, verilog_number("1'b1")),
            component_insts(component_inst(:a))
          ),
          code
        )

        code = 'field {} b=0;'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:b, reset_value(number(0))))
          ),
          code
        )

        code = 'field { anded;} a[4]=0;'
        assert_parses(
          field_anonymous_definition(
            prop_assignment(:anded),
            component_insts(component_inst(:a, array(4), reset_value(number(0))))
          ),
          code
        )
      end

      def test_register_component
        code = 'reg myReg { field {} data[31:0]; };'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            field_anonymous_definition(
              component_insts(component_inst(:data, range(31, 0)))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a[2], reg_b[2][4];'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, array(2)),
              component_inst(:reg_b, array(2), array(4))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a @ 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, address_assignment(number('0x10')))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_b[10] @0x100 += 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(
                :reg_b,
                array(10),
                address_assignment(number('0x100')),
                address_stride(number('0x10')),
              )
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a %= 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, address_alignment(number('0x10')))
            )
          ),
          code
        )

        code = 'reg {} external reg_a , reg_b;'
        assert_parses(
          reg_anonymous_definition(
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'reg myReg {} external reg_a , reg_b;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'external reg {} reg_a , reg_b;'
        assert_parses(
          reg_anonymous_definition(
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'external reg myReg {} reg_a , reg_b;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = <<~'R'
          reg {
            field f_type {};
            f_type some_field;
          } some_reg;
        R
        assert_parses(
          reg_anonymous_definition(
            field_named_definition(id(:f_type)),
            explicit_component_inst(
              :f_type,
              component_insts(component_inst(:some_field))
            ),
            component_insts(component_inst(:some_reg))
          ),
          code
        )

        code = <<~'R'
          reg {
            field {} f1;
            f1->name = "New name for Field 1";
          } some_reg;
        R
        assert_parses(
          reg_anonymous_definition(
            field_anonymous_definition(
              component_insts(component_inst(:f1))
            ),
            post_prop_assignment(
              [:f1], :name, string('"New name for Field 1"')
            ),
            component_insts(
              component_inst(:some_reg)
            )
          ),
          code
        )

        code = <<~'R'
          reg my32bitReg {
            regwidth = 32;
            accesswidth = 16;
            field {} a[16]=0;
            field {} b[32]=1;
          };
        R
        assert_parses(
          reg_named_definition(
            id(:my32bitReg),
            prop_assignment(:regwidth, number(32)),
            prop_assignment(:accesswidth, number(16)),
            field_anonymous_definition(
              component_insts(
                component_inst(:a, array(16), reset_value(number(0)))
              )
            ),
            field_anonymous_definition(
              component_insts(
                component_inst(:b, array(32), reset_value(number(1)))
              )
            )
          ),
          code
        )
      end

      def test_memory_component
        code = <<~'M'
          mem fifo_mem {
            mementries = 1024;
            memwidth = 32;
          };
        M
        assert_parses(
          mem_named_definition(
            id(:fifo_mem),
            prop_assignment(:mementries, number(1024)),
            prop_assignment(:memwidth, number(32))
          ),
          code
        )

        code = <<~'M'
          external mem fifo_mem {
            mementries = 1024;
            memwidth = 32;
          } mem_a, mem_b;
        M
        assert_parses(
          mem_named_definition(
            id(:fifo_mem),
            prop_assignment(:mementries, number(1024)),
            prop_assignment(:memwidth, number(32)),
            external_component_insts(
              component_inst(:mem_a),
              component_inst(:mem_b),
            )
          ),
          code
        )

        code = <<~'M'
          mem {
            mementries = 1024;
            memwidth = 32;
          } external mem_a, mem_b;
        M
        assert_parses(
          mem_anonymous_definition(
            prop_assignment(:mementries, number(1024)),
            prop_assignment(:memwidth, number(32)),
            external_component_insts(
              component_inst(:mem_a),
              component_inst(:mem_b),
            )
          ),
          code
        )
      end

      def test_register_file_component
        code = <<~'RF'
          regfile fifo_rfile {
            alignment = 8;
            reg {field {} a;} a;
            reg {field {} b;} b;
          };
        RF
        assert_parses(
          regfile_named_definition(
            id(:fifo_rfile),
            prop_assignment(:alignment, number(8)),
            reg_anonymous_definition(
              field_anonymous_definition(component_insts(component_inst(:a))),
              component_insts(component_inst(:a))
            ),
            reg_anonymous_definition(
              field_anonymous_definition(component_insts(component_inst(:b))),
              component_insts(component_inst(:b))
            )
          ),
          code
        )

        code = <<~'RF'
          regfile {
            external fifo_rfile fifo_a;
            external fifo_rfile fifo_b[64];
            sharedextbus;
          } top_regfile;
        RF
        assert_parses(
          regfile_anonymous_definition(
            explicit_component_inst(
              :fifo_rfile,
              external_component_insts(component_inst(:fifo_a))
            ),
            explicit_component_inst(
              :fifo_rfile,
              external_component_insts(component_inst(:fifo_b, array(64)))
            ),
            prop_assignment(:sharedextbus),
            component_insts(component_inst(:top_regfile))
          ),
          code
        )

        code = <<~'RF'
          external regfile {} a;
        RF
        assert_parses(
          regfile_anonymous_definition(external_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          internal regfile {} a;
        RF
        assert_parses(
          regfile_anonymous_definition(internal_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          regfile {} external a;
        RF
        assert_parses(
          regfile_anonymous_definition(external_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          regfile {} internal a;
        RF
        assert_parses(
          regfile_anonymous_definition(internal_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          external regfile rf {} a;
        RF
        assert_parses(
          regfile_named_definition(id(:rf), external_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          internal regfile rf {} a;
        RF
        assert_parses(
          regfile_named_definition(id(:rf), internal_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          regfile rf {} external a;
        RF
        assert_parses(
          regfile_named_definition(id(:rf), external_component_insts(component_inst(:a))),
          code
        )

        code = <<~'RF'
          regfile rf {} internal a;
        RF
        assert_parses(
          regfile_named_definition(id(:rf), internal_component_insts(component_inst(:a))),
          code
        )
      end

      def test_address_map
        code = <<~'AM'
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
        assert_parses(
          addrmap_named_definition(
            id(:some_bridge),
            prop_assignment(
              :desc,
              string('"overlapping address maps with both shared register space and orthogonal register space"')
            ),
            prop_assignment(:bridge),
            reg_named_definition(
              id(:status),
              prop_assignment(:shared),
              field_anonymous_definition(
                prop_assignment(:hw, access_type(:rw)),
                prop_assignment(:sw, access_type(:r)),
                component_insts(
                  component_inst(
                    :stat1,
                    reset_value(verilog_number("1'b0"))
                  )
                )
              )
            ),
            reg_named_definition(
              id(:some_axi_reg),
              field_anonymous_definition(
                prop_assignment(
                  :desc,
                  string('"credits on the AXI interface"')
                ),
                component_insts(
                  component_inst(
                    :credits,
                    array(4),
                    reset_value(verilog_number("4'h7"))
                  )
                )
              )
            ),
            reg_named_definition(
              id(:some_ahb_reg),
              field_anonymous_definition(
                prop_assignment(
                  :desc,
                  string('"credits on the AHB Interface"')
                ),
                component_insts(
                  component_inst(
                    :credits,
                    array(8),
                    reset_value(verilog_number("8'b00000011"))
                  )
                )
              )
            ),
            addrmap_anonymous_definition(
              prop_assignment(:littleendian),
              explicit_component_inst(
                :some_ahb_reg,
                component_insts(
                  component_inst(:ahb_credits)
                )
              ),
              explicit_component_inst(
                :status,
                component_insts(
                  component_inst(
                    :ahb_stat,
                    address_assignment(number('0x20'))
                  )
                )
              ),
              post_prop_assignment([:ahb_stat, :stat1], :desc, string('"bar"')),
              component_insts(component_inst(:ahb))
            )
          ),
          code
        )
      end

      def addrmap_anonymous_definition(*children)
        s(:component_anon_def, 'addrmap', *children)
      end

      def addrmap_named_definition(*children)
        s(:component_named_def, 'addrmap', *children)
      end

      def regfile_anonymous_definition(*children)
        s(:component_anon_def, 'regfile', *children)
      end

      def regfile_named_definition(*children)
        s(:component_named_def, 'regfile', *children)
      end

      def mem_anonymous_definition(*children)
        s(:component_anon_def, 'mem', *children)
      end

      def mem_named_definition(*children)
        s(:component_named_def, 'mem', *children)
      end

      def reg_anonymous_definition(*children)
        s(:component_anon_def, 'reg', *children)
      end

      def reg_named_definition(*children)
        s(:component_named_def, 'reg', *children)
      end

      def field_anonymous_definition(*children)
        s(:component_anon_def, 'field', *children)
      end

      def field_named_definition(*children)
        s(:component_named_def, 'field', *children)
      end

      def component_insts(*children)
        s(:component_insts, *children)
      end

      def component_inst(id, *children)
        s(:component_inst, id(id), *children)
      end

      def external_component_insts(*children)
        s(:external_component_insts, *children)
      end

      def internal_component_insts(*children)
        s(:internal_component_insts, *children)
      end

      def explicit_component_inst(component_name, insts)
        s(:explicit_component_inst, id(component_name), insts)
      end

      def id(name)
        s(:id, name.to_s)
      end

      def array(size)
        s(:array, number(size))
      end

      def range(head, tail)
        s(:range, number(head), number(tail))
      end

      def reset_value(value)
        s(:reset_value, value)
      end

      def address_assignment(expression)
        s(:address_assignment, expression)
      end

      def address_stride(expression)
        s(:address_stride, expression)
      end

      def address_alignment(expression)
        s(:address_alignment, expression)
      end

      def number(n)
        s(:number, n.to_s)
      end

      def verilog_number(n)
        s(:verilog_number, n)
      end

      def string(s)
        s(:string, s)
      end

      def access_type(type)
        s(:access_type, type.to_s)
      end

      def prop_assignment(prop_name, value = nil)
        s(:prop_assignment, *[id(prop_name), value].compact)
      end

      def post_prop_assignment(inst_names, prop_name, value)
        inst_elements =
          inst_names.map { |name| s(:instance_ref_element, id(name)) }
        prop_ref = s(
          :prop_ref,
          s(:instance_ref, *inst_elements),
          id(prop_name)
        )
        s(:post_prop_assignment, prop_ref, value)
      end
    end
  end
end
