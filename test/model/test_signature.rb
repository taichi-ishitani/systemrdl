# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Model
    class TestSignature < TestCase
      def test_signature_for_parameterized_component
        template = proc do |pattern, component_def, component_name, override|
          case pattern
          when 0 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                #{component_name} a;
                #{component_name} b;
              };
            RDL
          when 1 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                #{component_name} a;
                #{component_name} #(.#{override}) b;
              };
            RDL
          when 2 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                external #{component_name} a;
                external #{component_name} b;
              };
            RDL
          when 3 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                external #{component_name} a;
                external #{component_name} #(.#{override}) b;
              };
            RDL
          when 4 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                reg {
                  #{component_name} a;
                  #{component_name} b;
                } a;
              };
            RDL
          when 5 then
            <<~RDL
              #{component_def}
              addrmap my_map {
                reg {
                  #{component_name} a;
                  #{component_name} #(.#{override}) b;
                } a;
              };
            RDL
          end
        end

        addrmap_def = <<~RDL
          addrmap addrmap_a #(
            longint unsigned A = 0,
            bit unsigned     B = 1'b0,
            boolean          C = false,
            string           D = "foo",
            accesstype       E = rw,
            addressingtype   F = compact,
            onreadtype       G = rclr,
            onwritetype      H = woclr,
            longint unsigned I = A + 1
          ) {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
        RDL

        regfile_def = <<~RDL
          regfile regfile_a #(
            longint unsigned A = 0,
            bit unsigned     B = 1'b0,
            boolean          C = false,
            string           D = "foo",
            accesstype       E = rw,
            addressingtype   F = compact,
            onreadtype       G = rclr,
            onwritetype      H = woclr,
            longint unsigned I = A + 1
          ) {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
        RDL

        mem_def = <<~RDL
          mem mem_a #(
            longint unsigned A = 0,
            bit unsigned     B = 1'b0,
            boolean          C = false,
            string           D = "foo",
            accesstype       E = rw,
            addressingtype   F = compact,
            onreadtype       G = rclr,
            onwritetype      H = woclr,
            longint unsigned I = A + 1
          ) {
            memwidth = 32;
          };
        RDL

        reg_def = <<~RDL
          reg reg_a #(
            longint unsigned A = 0,
            bit unsigned     B = 1'b0,
            boolean          C = false,
            string           D = "foo",
            accesstype       E = rw,
            addressingtype   F = compact,
            onreadtype       G = rclr,
            onwritetype      H = woclr,
            longint unsigned I = A + 1
          ) {
            field { sw = rw; hw = r; } a;
          };
        RDL

        field_def = <<~RDL
          field field_a #(
            longint unsigned A = 0,
            bit unsigned     B = 1'b0,
            boolean          C = false,
            string           D = "foo",
            accesstype       E = rw,
            addressingtype   F = compact,
            onreadtype       G = rclr,
            onwritetype      H = woclr,
            longint unsigned I = A + 1
          ) {
            sw = rw; hw = r;
          };
        RDL

        addrmaps = build_model(template[0, addrmap_def, 'addrmap_a'])[1].regs
        assert_signature(addrmaps[1], addrmaps[0])

        regfiles = build_model(template[0, regfile_def, 'regfile_a'])[0].regs
        assert_signature(regfiles[1], regfiles[0])

        mems = build_model(template[2, mem_def, 'mem_a'])[0].regs
        assert_signature(mems[1], mems[0])

        regs = build_model(template[0, reg_def, 'reg_a'])[0].regs
        assert_signature(regs[1], regs[0])

        fields = build_model(template[4, field_def, 'field_a'])[0].regs[0].fields
        assert_signature(fields[1], fields[0])

        [
          'A(0)', 'B(1\'b0)', 'C(false)', 'D("foo")', 'E(rw)',
          'F(compact)', 'G(rclr)', 'H(woclr)'
        ].each do |override|
          addrmaps = build_model(template[1, addrmap_def, 'addrmap_a', override])[1].regs
          assert_signature(addrmaps[1], addrmaps[0])

          regfiles = build_model(template[1, regfile_def, 'regfile_a', override])[0].regs
          assert_signature(regfiles[1], regfiles[0])

          mems = build_model(template[3, mem_def, 'mem_a', override])[0].regs
          assert_signature(mems[1], mems[0])

          regs = build_model(template[1, reg_def, 'reg_a', override])[0].regs
          assert_signature(regs[1], regs[0])

          fields = build_model(template[5, field_def, 'field_a', override])[0].regs[0].fields
          assert_signature(fields[1], fields[0])
        end

        [
          'A(1)', 'B(2\'b0)', 'C(true)', 'D("bar")', 'E(r)',
          'F(regalign)', 'G(rset)', 'H(woset)'
        ].each do |override|
          addrmaps = build_model(template[1, addrmap_def, 'addrmap_a', override])[1].regs
          refute_signature(addrmaps[1], addrmaps[0])

          regfiles = build_model(template[1, regfile_def, 'regfile_a', override])[0].regs
          refute_signature(regfiles[1], regfiles[0])

          mems = build_model(template[3, mem_def, 'mem_a', override])[0].regs
          refute_signature(mems[1], mems[0])

          regs = build_model(template[1, reg_def, 'reg_a', override])[0].regs
          refute_signature(regs[1], regs[0])

          fields = build_model(template[5, field_def, 'field_a', override])[0].regs[0].fields
          refute_signature(fields[1], fields[0])
        end

        override = 'I(1)'
        addrmaps = build_model(template[1, addrmap_def, 'addrmap_a', override])[1].regs
        assert_signature(addrmaps[1], addrmaps[0])

        regfiles = build_model(template[1, regfile_def, 'regfile_a', override])[0].regs
        assert_signature(regfiles[1], regfiles[0])

        mems = build_model(template[3, mem_def, 'mem_a', override])[0].regs
        assert_signature(mems[1], mems[0])

        regs = build_model(template[1, reg_def, 'reg_a', override])[0].regs
        assert_signature(regs[1], regs[0])

        fields = build_model(template[5, field_def, 'field_a', override])[0].regs[0].fields
        assert_signature(fields[1], fields[0])

        override = 'I(2)'
        addrmaps = build_model(template[1, addrmap_def, 'addrmap_a', override])[1].regs
        refute_signature(addrmaps[1], addrmaps[0])

        regfiles = build_model(template[1, regfile_def, 'regfile_a', override])[0].regs
        refute_signature(regfiles[1], regfiles[0])

        mems = build_model(template[3, mem_def, 'mem_a', override])[0].regs
        refute_signature(mems[1], mems[0])

        regs = build_model(template[1, reg_def, 'reg_a', override])[0].regs
        refute_signature(regs[1], regs[0])

        fields = build_model(template[5, field_def, 'field_a', override])[0].regs[0].fields
        refute_signature(fields[1], fields[0])
      end

      def test_signature_for_non_parameterized_component
        addrmaps = build_model(<<~RDL)[2].regs
          addrmap addrmap_a {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap addrmap_b {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap my_map {
            addrmap_a a;
            addrmap_b b;
            addrmap_a c;
          };
        RDL
        refute_signature(addrmaps[1], addrmaps[0])
        assert_signature(addrmaps[2], addrmaps[0])

        regfiles = build_model(<<~RDL)[0].regs
          regfile regfile_a {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          regfile regfile_b {
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap my_map {
            regfile_a a;
            regfile_b b;
            regfile_a c;
          };
        RDL
        refute_signature(regfiles[1], regfiles[0])
        assert_signature(regfiles[2], regfiles[0])

        mems = build_model(<<~RDL)[0].regs
          mem mem_a {
            memwidth = 32;
          };
          mem mem_b {
            memwidth = 32;
          };
          addrmap my_map {
            external mem_a a;
            external mem_b b;
            external mem_a c;
          };
        RDL
        refute_signature(mems[1], mems[0])
        assert_signature(mems[2], mems[0])

        regs = build_model(<<~RDL)[0].regs
          reg reg_a {
            field { sw = rw; hw = r; } a;
          };
          reg reg_b {
            field { sw = rw; hw = r; } a;
          };
          addrmap my_map {
            reg_a a;
            reg_b b;
            reg_a c;
          };
        RDL
        refute_signature(regs[1], regs[0])
        assert_signature(regs[2], regs[0])

        fields = build_model(<<~RDL)[0].regs[0].fields
          field field_a {
            sw = rw; hw = r;
          };
          field field_b {
            sw = rw; hw = r;
          };
          addrmap my_map {
            reg {
              field_a a;
              field_b b;
              field_a c;
            } a;
          };
        RDL
        refute_signature(fields[1], fields[0])
        assert_signature(fields[2], fields[0])
      end

      def test_signature_for_anonymous_component
        addrmap = build_model(<<~RDL)[0]
          addrmap my_map {
            addrmap {
              regfile {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a;
              external mem {
                memwidth = 32;
              } b;
            } a;
          };
        RDL

        addrmap = addrmap.regs[0]
        assert_nil(addrmap.signature)

        regfile = addrmap.regs[0]
        assert_nil(regfile.signature)

        mem = addrmap.regs[1]
        assert_nil(mem.signature)

        reg = regfile.regs[0]
        assert_nil(reg.signature)

        field = reg.fields[0]
        assert_nil(field.signature)
      end

      def test_signature_differs_by_lexical_scope
        addrmap = build_model(<<~RDL)[0]
          regfile regfile_a {
            reg my_reg {
              field my_field #(longint unsigned WIDTH = 8) {
                sw = rw; hw = r; fieldwidth = WIDTH;
              };
              my_field #(.WIDTH(16)) a;
            };
            my_reg a;
          };
          regfile regfile_b {
            reg my_reg {
              field my_field #(longint unsigned WIDTH = 8) {
                sw = rw; hw = r; fieldwidth = WIDTH;
              };
              my_field #(.WIDTH(16)) a;
            };
            my_reg a;
          };
          addrmap my_map {
            regfile_a a;
            regfile_b b;
            regfile_a c;
          };
        RDL

        fields = collect_fields(addrmap)
        refute_signature(fields[1], fields[0])
        assert_signature(fields[2], fields[0])
      end
    end
  end
end
