# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Model
    class TestEnum < TestCase
      def test_type_defined_in_outer_scope_is_resolved_lexically
        model = build_model(<<~'RDL')
          addrmap my_map {
            enum ab { A = 0; };
            field my_field {
              sw = rw; hw = r;
              encode = ab;
            };
            reg {
              enum ab { B = 1; };
              my_field a;
            } a;
          };
        RDL

        field = collect_fields(model.instances[0])[0]
        encode = field.encode

        assert_equal(['A'], encode.members.map(&:name))
        assert_same(model.instances[0].types[0], encode)
      end

      def test_enum_defined_in_the_referring_field_is_resolved
        model = build_model(<<~'RDL')
          addrmap my_map {
            reg {
              field {
                enum e { A = 0; B = 1; };
                sw = rw; hw = r;
                encode = e;
              } a;
            } r0;
          };
        RDL

        field = collect_fields(model.instances[0])[0]

        assert_equal(['e'], field.types.map(&:name))
        assert_same(field.types[0], field.encode)
      end

      def test_enum_is_elaborated_per_instance
        model = build_model(<<~'RDL')
          addrmap my_map {
            reg my_reg #(longint unsigned BASE = 0) {
              enum e { A = BASE; B = BASE + 1; };
              field { sw = rw; hw = r; fieldwidth = 8; encode = e; } a;
            };
            my_reg x;
            my_reg #(.BASE(16)) y;
          };
        RDL

        regs = collect_regs(model.instances[0])
        fields = collect_fields(model.instances[0])

        [[0, 1], [16, 17]].each_with_index do |values, i|
          assert_equal(values, regs[i].types[0].members.map(&:value))
        end

        refute_same(regs[0].types[0], regs[1].types[0])
        assert_same(regs[0].types[0], fields[0].encode)
        assert_same(regs[1].types[0], fields[1].encode)
      end

      def test_enum_referenced_from_multiple_fields_is_shared
        model = build_model(<<~'RDL')
          addrmap my_map {
            enum ab { A = 0; B = 1; };
            reg {
              field { sw = rw; hw = r; encode = ab; } a;
              field { sw = rw; hw = r; } b;
              b->encode = ab;
            } r0;
          };
        RDL

        fields = collect_fields(model.instances[0])

        assert_same(model.instances[0].types[0], fields[0].encode)
        assert_same(fields[0].encode, fields[1].encode)
      end

      def test_inner_definition_shadows_outer_definition
        model = build_model(<<~'RDL')
          addrmap my_map {
            enum ab { A = 0; };
            reg {
              enum ab { B = 1; };
              field { sw = rw; hw = r; encode = ab; } a;
            } r0;
          };
        RDL

        reg = collect_regs(model.instances[0])[0]
        encode = collect_fields(model.instances[0])[0].encode

        assert_equal(['B'], encode.members.map(&:name))
        assert_same(reg.types[0], encode)
      end

      def test_unreferenced_enum_is_retained
        model = build_model(<<~'RDL')
          addrmap my_map {
            enum unreferenced { A = 0; };
            reg {
              field { sw = rw; hw = r; } a;
            } r0;
          };
        RDL

        assert_equal(['unreferenced'], model.instances[0].types.map(&:name))
        assert_nil(collect_fields(model.instances[0])[0].encode)
      end
    end
  end
end
