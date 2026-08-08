# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Model
    class TestModel < TestCase
      def setup
        @addrmaps = build_model(<<~'RDL')
          addrmap my_map {
            name = "Sample";

            reg {
              field { sw = r; hw = w; reset = 0; anded; } a;
              field { sw = rw; hw = r; reset = 4'h0; we; } b[4];
            } r0;

            reg {
              field { sw = r; hw = w; } a;
              field { sw = r; hw = rw; hwclr; precedence = hw; } b;
            } r1[2];

            reg {
              field { sw = r; hw = w; } a;
              field { sw = r; hw = rw; hwclr; } b;
            } r2;

            regfile {
              reg {
                field { sw = rw; hw = r; } a;
              } r0;
            } rf0;

            external mem {
              memwidth = 24;
              mementries = 4;
            } mem0;

            addrmap {
              reg {
                field { sw = rw; hw = r; } a;
              } r0;
            } sub0;

            r2.a->hwenable = r0.b;
            r2.b->hwset = r0.a->anded;
          };
        RDL
      end

      def test_addrmap_accessors
        addrmap = @addrmaps[0]
        assert_value('my_map', addrmap.name)
        assert_value('my_map', addrmap.full_name)
        assert_value('Sample', addrmap.display_name)
        assert_value('', addrmap.desc)
        assert_value(nil, addrmap.address)
        assert_value(52, addrmap.size)
        assert_value(32, addrmap.accesswidth)
        assert_value(false, addrmap.sharedextbus)
        assert_value(false, addrmap.errextbus)
        assert_value(false, addrmap.bigendian)
        assert_value(false, addrmap.littleendian)
        assert_value(false, addrmap.rsvdset)
        assert_value(false, addrmap.rsvdsetX)

        addrmap = @addrmaps[0].regs[6]
        assert_value('sub0', addrmap.name)
        assert_value('my_map.sub0', addrmap.full_name)
        assert_value('sub0', addrmap.display_name)
        assert_value('', addrmap.desc)
        assert_value(0x30, addrmap.address)
        assert_value(4, addrmap.size)
        assert_value(32, addrmap.accesswidth)
        assert_value(false, addrmap.sharedextbus)
        assert_value(false, addrmap.errextbus)
        assert_value(false, addrmap.bigendian)
        assert_value(false, addrmap.littleendian)
        assert_value(false, addrmap.rsvdset)
        assert_value(false, addrmap.rsvdsetX)
      end

      def test_addrmap_properties
        addrmap = @addrmaps[0]
        assert_property_value(addrmap, :display_name, 'Sample')
        assert_property_value(addrmap, :desc, '')
        assert_property_value(addrmap, :sharedextbus, false)
        assert_property_value(addrmap, :errextbus, false)
        assert_property_value(addrmap, :bigendian, false)
        assert_property_value(addrmap, :littleendian, false)
        assert_property_value(addrmap, :rsvdset, false)
        assert_property_value(addrmap, :rsvdsetX, false)

        addrmap = @addrmaps[0].regs[6]
        assert_property_value(addrmap, :display_name, 'sub0')
        assert_property_value(addrmap, :desc, '')
        assert_property_value(addrmap, :sharedextbus, false)
        assert_property_value(addrmap, :errextbus, false)
        assert_property_value(addrmap, :bigendian, false)
        assert_property_value(addrmap, :littleendian, false)
        assert_property_value(addrmap, :rsvdset, false)
        assert_property_value(addrmap, :rsvdsetX, false)
      end

      def test_addrmap_dropped_properties
        [@addrmaps[0], @addrmaps[0].regs[6]].each do |addrmap|
          refute_property(addrmap, :alignment)
          refute_property(addrmap, :addressing)
          refute_property(addrmap, :msb0)
          refute_property(addrmap, :lsb0)
        end
      end

      def test_mem_accessors
        mem = @addrmaps[0].regs[5]
        assert_value('mem0', mem.name)
        assert_value('my_map.mem0', mem.full_name)
        assert_value('mem0', mem.display_name)
        assert_value('', mem.desc)
        assert_value(0x20, mem.address)
        assert_value(16, mem.size)
        assert_value(32, mem.accesswidth)
        assert_value(32, mem.entrywidth)
        assert_value(24, mem.memwidth)
        assert_value(4, mem.mementries)
        assert_value(:rw, mem.sw)
      end

      def test_mem_propertyes
        mem = @addrmaps[0].regs[5]
        assert_property_value(mem, :display_name, 'mem0')
        assert_property_value(mem, :desc, '')
        assert_property_value(mem, :memwidth, 24)
        assert_property_value(mem, :mementries, 4)
        assert_property_value(mem, :sw, :rw)
      end

      def test_regfile_accessors
        regfile = @addrmaps[0].regs[4]
        assert_value('rf0', regfile.name)
        assert_value('my_map.rf0', regfile.full_name)
        assert_value('rf0', regfile.display_name)
        assert_value('', regfile.desc)
        assert_value(false, regfile.external)
        assert_value(0x10, regfile.address)
        assert_value(4, regfile.size)
        assert_value(32, regfile.accesswidth)
        assert_value(false, regfile.sharedextbus)
        assert_value(false, regfile.errextbus)
      end

      def test_regfile_properties
        regfile = @addrmaps[0].regs[4]
        assert_property_value(regfile, :display_name, 'rf0')
        assert_property_value(regfile, :desc, '')
        assert_property_value(regfile, :sharedextbus, false)
        assert_property_value(regfile, :errextbus, false)
      end

      def test_regfile_dropped_properties
        regfile = @addrmaps[0].regs[4]
        refute_property(regfile, :alignment)
      end

      def test_reg_accessors
        regs = collect_regs(@addrmaps[0])

        ['r0', 'r1[0]', 'r1[1]', 'r2', 'r0', 'r0'].each_with_index do |name, i|
          assert_value(name, regs[i].name)
        end

        [
          'my_map.r0', 'my_map.r1[0]', 'my_map.r1[1]', 'my_map.r2', 'my_map.rf0.r0', 'my_map.sub0.r0'
        ].each_with_index do |full_name, i|
          assert_value(full_name, regs[i].full_name)
        end

        ['r0', 'r1', 'r1', 'r2', 'r0', 'r0'].each_with_index do |display_name, i|
          assert_value(display_name, regs[i].display_name)
        end

        ['', '', '', '', '', ''].each_with_index do |desc, i|
          assert_value(desc, regs[i].desc)
        end

        [false, false, false, false, false, false].each_with_index do |external, i|
          assert_value(external, regs[i].external)
        end

        [0x0, 0x4, 0x8, 0xC, 0x0, 0x0].each_with_index do |address, i|
          assert_value(address, regs[i].address)
        end

        [4, 4, 4, 4, 4, 4].each_with_index do |size, i|
          assert_value(size, regs[i].size)
        end

        [32, 32, 32, 32, 32, 32].each_with_index do |accesswidth, i|
          assert_value(accesswidth, regs[i].accesswidth)
        end

        [false, false, false, false, false, false].each_with_index do |errextbus, i|
          assert_value(errextbus, regs[i].errextbus)
        end

        [false, false, false, false, false, false].each_with_index do |shared, i|
          assert_value(shared, regs[i].shared)
        end
      end

      def test_reg_properties
        regs = collect_regs(@addrmaps[0])

        ['r0', 'r1', 'r1', 'r2', 'r0', 'r0'].each_with_index do |display_name, i|
          assert_property_value(regs[i], :display_name, display_name)
        end

        ['', '', '', '', '', ''].each_with_index do |desc, i|
          assert_property_value(regs[i], :desc, desc)
        end

        [0x0, 0x4, 0x8, 0xC, 0x0, 0x0].each_with_index do |address, i|
          assert_property_value(regs[i], :address, address)
        end

        [32, 32, 32, 32, 32, 32].each_with_index do |accesswidth, i|
          assert_property_value(regs[i], :accesswidth, accesswidth)
        end

        [false, false, false, false, false, false].each_with_index do |errextbus, i|
          assert_property_value(regs[i], :errextbus, errextbus)
        end

        [false, false, false, false, false, false].each_with_index do |shared, i|
          assert_property_value(regs[i], :shared, shared)
        end
      end

      def test_reg_dropped_properties
        regs = collect_regs(@addrmaps[0])

        regs.each do |reg|
          refute_property(reg, :regwidth)
          refute_property(reg, :alignment)
        end
      end

      def test_field_accessors
        fields = collect_fields(@addrmaps[0])

        ['a', 'b', 'a', 'b', 'a', 'b', 'a', 'b', 'a', 'a'].each_with_index do |v, i|
          assert_value(v, fields[i].name)
        end

        [
          'my_map.r0.a', 'my_map.r0.b', 'my_map.r1[0].a', 'my_map.r1[0].b',
          'my_map.r1[1].a', 'my_map.r1[1].b', 'my_map.r2.a', 'my_map.r2.b',
          'my_map.rf0.r0.a', 'my_map.sub0.r0.a'
        ].each_with_index do |v, i|
          assert_value(v, fields[i].full_name)
        end

        ['a', 'b', 'a', 'b', 'a', 'b', 'a', 'b', 'a', 'a'].each_with_index do |v, i|
          assert_value(v, fields[i].display_name)
        end

        ['', '', '', '', '', '', '', '', '', ''].each_with_index do |v, i|
          assert_value(v, fields[i].desc)
        end

        [0, 4, 0, 1, 0, 1, 0, 1, 0, 0].each_with_index do |v, i|
          assert_value(v, fields[i].msb)
        end

        [0, 1, 0, 1, 0, 1, 0, 1, 0, 0].each_with_index do |v, i|
          assert_value(v, fields[i].lsb)
        end

        [1, 4, 1, 1, 1, 1, 1, 1, 1, 1].each_with_index do |v, i|
          assert_value(v, fields[i].width)
        end

        [:w, :r, :w, :rw, :w, :rw, :w, :rw, :r, :r].each_with_index do |v, i|
          assert_value(v, fields[i].hw)
        end

        [:r, :rw, :r, :r, :r, :r, :r, :r, :rw, :rw].each_with_index do |v, i|
          assert_value(v, fields[i].sw)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].next)
        end

        [0, 0, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].reset)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].resetsignal)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].rclr)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].rset)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].onread)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].woset)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].woclr)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].onwrite)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].swwe)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].swwel)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].swmod)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].swacc)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].singlepulse)
        end

        [false, true, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].we)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].wel)
        end

        [true, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].anded)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].ored)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].xored)
        end

        [false, false, false, true, false, true, false, true, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].hwclr)
        end

        [false, false, false, false, false, false, false, 'my_map.r0.a.anded', false, false].each_with_index do |expected, i|
          if expected
            assert_reference_value(expected, fields[i].hwset)
          else
            assert_value(expected, fields[i].hwset)
          end
        end

        [nil, nil, nil, nil, nil, nil, 'my_map.r0.b', nil, nil, nil].each_with_index do |expected, i|
          if expected
            assert_reference_value(expected, fields[i].hwenable)
          else
            assert_nil(fields[i].hwenable)
          end
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_value(v, fields[i].hwmask)
        end

        [:sw, :sw, :sw, :hw, :sw, :hw, :sw, :sw, :sw, :sw].each_with_index do |v, i|
          assert_value(v, fields[i].precedence)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_value(v, fields[i].paritycheck)
        end
      end

      def test_field_properties
        fields = collect_fields(@addrmaps[0])

        ['a', 'b', 'a', 'b', 'a', 'b', 'a', 'b', 'a', 'a'].each_with_index do |v, i|
          assert_property_value(fields[i], :display_name, v)
        end

        ['', '', '', '', '', '', '', '', '', ''].each_with_index do |v, i|
          assert_property_value(fields[i], :desc, v)
        end

        [:w, :r, :w, :rw, :w, :rw, :w, :rw, :r, :r].each_with_index do |v, i|
          assert_property_value(fields[i], :hw, v)
        end

        [:r, :rw, :r, :r, :r, :r, :r, :r, :rw, :rw].each_with_index do |v, i|
          assert_property_value(fields[i], :sw, v)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :next, v)
        end

        [0, 0, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :reset, v)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :resetsignal, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :rclr, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :rset, v)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :onread, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :woset, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :woclr, v)
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :onwrite, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :swwe, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :swwel, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :swmod, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :swacc, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :singlepulse, v)
        end

        [false, true, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :we, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :wel, v)
        end

        [true, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :anded, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :ored, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :xored, v)
        end

        [false, false, false, true, false, true, false, true, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :hwclr, v)
        end

        [false, false, false, false, false, false, false, 'my_map.r0.a.anded', false, false].each_with_index do |expected, i|
          if expected
            assert_property_reference_value(fields[i], :hwset, expected)
          else
            assert_property_value(fields[i], :hwset, expected)
          end
        end

        [nil, nil, nil, nil, nil, nil, 'my_map.r0.b', nil, nil, nil].each_with_index do |expected, i|
          if expected
            assert_property_reference_value(fields[i], :hwenable, expected)
          else
            assert_property_value(fields[i], :hwenable, expected)
          end
        end

        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].each_with_index do |v, i|
          assert_property_value(fields[i], :hwmask, v)
        end

        [:sw, :sw, :sw, :hw, :sw, :hw, :sw, :sw, :sw, :sw].each_with_index do |v, i|
          assert_property_value(fields[i], :precedence, v)
        end

        [false, false, false, false, false, false, false, false, false, false].each_with_index do |v, i|
          assert_property_value(fields[i], :paritycheck, v)
        end
      end

      def test_field_dropped_properties
        fields = collect_fields(@addrmaps[0])

        fields.each do |field|
          refute_property(field, :fieldwidth)
        end
      end

      def test_type_identifier
        fields = collect_fields(@addrmaps[0])

        prop = fields[0].property(:hwset)
        assert(prop.value?)
        refute(prop.instance_ref?)
        refute(prop.property_ref?)

        prop = fields[0].property(:reset)
        assert(prop.value?)
        refute(prop.instance_ref?)
        refute(prop.property_ref?)

        prop = fields[6].property(:hwenable)
        refute(prop.value?)
        assert(prop.instance_ref?)
        refute(prop.property_ref?)

        prop = fields[7].property(:hwset)
        refute(prop.value?)
        refute(prop.instance_ref?)
        assert(prop.property_ref?)
      end

      def test_pp
        addrmap = @addrmaps[0]
        assert_output(<<~'PP') { pp addrmap }
          my_map (addrmap) {
            display_name: "Sample"
            desc: ""
            address: nil
            size: 52
            accesswidth: 32
            sharedextbus: false
            errextbus: false
            bigendian: false
            littleendian: false
            rsvdset: false
            rsvdsetX: false
            r0 (reg) {
              display_name: "r0"
              desc: ""
              external: false
              address: 0x0
              size: 4
              accesswidth: 32
              errextbus: false
              shared: false
              a (field) {
                display_name: "a"
                desc: ""
                msb: 0
                lsb: 0
                width: 1
                hw: :w
                sw: :r
                next: nil
                reset: 0x0
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: true
                ored: false
                xored: false
                hwclr: false
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :sw
                paritycheck: false}
              b (field) {
                display_name: "b"
                desc: ""
                msb: 4
                lsb: 1
                width: 4
                hw: :r
                sw: :rw
                next: nil
                reset: 0x0
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: true
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: false
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :sw
                paritycheck: false}}
            r1[0] (reg) {
              display_name: "r1"
              desc: ""
              external: false
              address: 0x4
              size: 4
              accesswidth: 32
              errextbus: false
              shared: false
              a (field) {
                display_name: "a"
                desc: ""
                msb: 0
                lsb: 0
                width: 1
                hw: :w
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: false
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :sw
                paritycheck: false}
              b (field) {
                display_name: "b"
                desc: ""
                msb: 1
                lsb: 1
                width: 1
                hw: :rw
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: true
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :hw
                paritycheck: false}}
            r1[1] (reg) {
              display_name: "r1"
              desc: ""
              external: false
              address: 0x8
              size: 4
              accesswidth: 32
              errextbus: false
              shared: false
              a (field) {
                display_name: "a"
                desc: ""
                msb: 0
                lsb: 0
                width: 1
                hw: :w
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: false
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :sw
                paritycheck: false}
              b (field) {
                display_name: "b"
                desc: ""
                msb: 1
                lsb: 1
                width: 1
                hw: :rw
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: true
                hwset: false
                hwenable: nil
                hwmask: nil
                precedence: :hw
                paritycheck: false}}
            r2 (reg) {
              display_name: "r2"
              desc: ""
              external: false
              address: 0xc
              size: 4
              accesswidth: 32
              errextbus: false
              shared: false
              a (field) {
                display_name: "a"
                desc: ""
                msb: 0
                lsb: 0
                width: 1
                hw: :w
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: false
                hwset: false
                hwenable: my_map.r0.b
                hwmask: nil
                precedence: :sw
                paritycheck: false}
              b (field) {
                display_name: "b"
                desc: ""
                msb: 1
                lsb: 1
                width: 1
                hw: :rw
                sw: :r
                next: nil
                reset: nil
                resetsignal: nil
                rclr: false
                rset: false
                onread: nil
                woset: false
                woclr: false
                onwrite: nil
                swwe: false
                swwel: false
                swmod: false
                swacc: false
                singlepulse: false
                we: false
                wel: false
                anded: false
                ored: false
                xored: false
                hwclr: true
                hwset: my_map.r0.a.anded
                hwenable: nil
                hwmask: nil
                precedence: :sw
                paritycheck: false}}
            rf0 (regfile) {
              display_name: "rf0"
              desc: ""
              external: false
              address: 0x10
              size: 4
              accesswidth: 32
              sharedextbus: false
              errextbus: false
              r0 (reg) {
                display_name: "r0"
                desc: ""
                external: false
                address: 0x0
                size: 4
                accesswidth: 32
                errextbus: false
                shared: false
                a (field) {
                  display_name: "a"
                  desc: ""
                  msb: 0
                  lsb: 0
                  width: 1
                  hw: :r
                  sw: :rw
                  next: nil
                  reset: nil
                  resetsignal: nil
                  rclr: false
                  rset: false
                  onread: nil
                  woset: false
                  woclr: false
                  onwrite: nil
                  swwe: false
                  swwel: false
                  swmod: false
                  swacc: false
                  singlepulse: false
                  we: false
                  wel: false
                  anded: false
                  ored: false
                  xored: false
                  hwclr: false
                  hwset: false
                  hwenable: nil
                  hwmask: nil
                  precedence: :sw
                  paritycheck: false}}}
            mem0 (mem) {
              display_name: "mem0"
              desc: ""
              address: 0x20
              size: 16
              accesswidth: 32
              entrywidth: 32
              memwidth: 24
              mementries: 4
              sw: :rw}
            sub0 (addrmap) {
              display_name: "sub0"
              desc: ""
              address: 0x30
              size: 4
              accesswidth: 32
              sharedextbus: false
              errextbus: false
              bigendian: false
              littleendian: false
              rsvdset: false
              rsvdsetX: false
              r0 (reg) {
                display_name: "r0"
                desc: ""
                external: false
                address: 0x0
                size: 4
                accesswidth: 32
                errextbus: false
                shared: false
                a (field) {
                  display_name: "a"
                  desc: ""
                  msb: 0
                  lsb: 0
                  width: 1
                  hw: :r
                  sw: :rw
                  next: nil
                  reset: nil
                  resetsignal: nil
                  rclr: false
                  rset: false
                  onread: nil
                  woset: false
                  woclr: false
                  onwrite: nil
                  swwe: false
                  swwel: false
                  swmod: false
                  swacc: false
                  singlepulse: false
                  we: false
                  wel: false
                  anded: false
                  ored: false
                  xored: false
                  hwclr: false
                  hwset: false
                  hwenable: nil
                  hwmask: nil
                  precedence: :sw
                  paritycheck: false}}}}
        PP
      end
    end
  end
end
