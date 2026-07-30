# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMap < TestCase
      def test_addrmap_without_structural_component_instance_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
            };
          RDL
          'no structural component instances within addrmap'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              name = "my map";
            };
          RDL
          'no structural component instances within addrmap'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg {
                field { sw = rw; hw = r; } a;
              };
            };
          RDL
          'no structural component instances within addrmap'
        )
      end

      def test_range_for_addrmap_instance_is_rejected
        skip 'not implemented yet'
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_addrmap {
              addrmap {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a[0:0];
            };
          RDL
          'range not allowed for addrmap instance'
        )
      end

      def test_address_stride_for_scalar_addrmap_instance_is_rejected
        skip 'not implemented yet'
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_addrmap {
              addrmap {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a += 0x4;
            };
          RDL
          'address stride not allowed for scalar addrmap instance'
        )
      end

      def test_power_of_2_alignment_is_accepted
        [1, 2, 4, 8, 16, 32].each do |alignment|
          addrmap = evaluate(<<~RDL).instances[0]
            addrmap my_map {
              alignment = #{alignment};
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            };
          RDL

          assert_property_value(addrmap, :alignment, alignment)
        end
      end

      def test_non_power_of_2_alignment_is_rejected
        [0, 3, 5, 7, 9, 15, 17, 31, 33].each do |alignment|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                alignment = #{alignment};
                reg {
                  field { sw = rw; hw = r; } a;
                }a ;
              };
            RDL
            "alignment must be a power of 2: #{alignment}"
          )
        end
      end

      def test_bigendian_littleendian_can_be_set_individually
        addrmaps = evaluate(<<~'RDL').instances
          addrmap a {
            bigendian = true;
            littleendian = false;
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap b {
            bigendian;
            reg {
              field { sw = rw; hw = r; } b;
            } b;
          };
          addrmap c {
            bigendian = false;
            littleendian = true;
            reg {
              field { sw = rw; hw = r; } c;
            } c;
          };
          addrmap d {
            littleendian;
            reg {
              field { sw = rw; hw = r; } d;
            } d;
          };
        RDL

        assert_property_value(addrmaps[0], :bigendian, true)
        assert_property_value(addrmaps[0], :littleendian, false)

        assert_property_value(addrmaps[1], :bigendian, true)
        assert_property_value(addrmaps[1], :littleendian, false)

        assert_property_value(addrmaps[2], :bigendian, false)
        assert_property_value(addrmaps[2], :littleendian, true)

        assert_property_value(addrmaps[3], :bigendian, false)
        assert_property_value(addrmaps[3], :littleendian, true)
      end

      def test_bigendian_littleendian_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              bigendian;
              littleendian;
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            };
          RDL
          'bigendian and littleendian properties are mutually exclusive'
        )
      end

      def test_rsvdset_rsvdsetx_can_be_set_individually
        addrmaps = evaluate(<<~'RDL').instances
          addrmap a {
            rsvdset = true;
            rsvdsetX = false;
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap b {
            rsvdset;
            reg {
              field { sw = rw; hw = r; } b;
            } b;
          };
          addrmap c {
            rsvdset = false;
            rsvdsetX = true;
            reg {
              field { sw = rw; hw = r; } c;
            } c;
          };
          addrmap d {
            rsvdsetX;
            reg {
              field { sw = rw; hw = r; } d;
            } d;
          };
        RDL

        assert_property_value(addrmaps[0], :rsvdset, true)
        assert_property_value(addrmaps[0], :rsvdsetX, false)

        assert_property_value(addrmaps[1], :rsvdset, true)
        assert_property_value(addrmaps[1], :rsvdsetX, false)

        assert_property_value(addrmaps[2], :rsvdset, false)
        assert_property_value(addrmaps[2], :rsvdsetX, true)

        assert_property_value(addrmaps[3], :rsvdset, false)
        assert_property_value(addrmaps[3], :rsvdsetX, true)
      end

      def test_rsvdset_rsvdsetx_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              rsvdset;
              rsvdsetX;
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            };
          RDL
          'rsvdset and rsvdsetX properties are mutually exclusive'
        )
      end

      def test_msb0_lsb0_can_be_set_individually
        addrmaps = evaluate(<<~'RDL').instances
          addrmap a {
            msb0 = true;
            lsb0 = false;
            reg {
              field { sw = rw; hw = r; } a;
            } a;
          };
          addrmap b {
            msb0;
            reg {
              field { sw = rw; hw = r; } b;
            } b;
          };
          addrmap c {
            msb0 = false;
            lsb0 = true;
            reg {
              field { sw = rw; hw = r; } c;
            } c;
          };
          addrmap d {
            lsb0;
            reg {
              field { sw = rw; hw = r; } d;
            } d;
          };
        RDL

        assert_property_value(addrmaps[0], :msb0, true)
        assert_property_value(addrmaps[0], :lsb0, false)

        assert_property_value(addrmaps[1], :msb0, true)
        assert_property_value(addrmaps[1], :lsb0, false)

        assert_property_value(addrmaps[2], :msb0, false)
        assert_property_value(addrmaps[2], :lsb0, true)

        assert_property_value(addrmaps[3], :msb0, false)
        assert_property_value(addrmaps[3], :lsb0, true)
      end

      def test_msb0_lsb0_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              msb0;
              lsb0;
              reg {
                field { sw = rw; hw = r; } a;
              }a ;
            };
          RDL
          'msb0 and lsb0 properties are mutually exclusive'
        )
      end

      def test_any_component_definitions_are_allowed
        addrmap = evaluate(<<~RDL).instances[0]
          addrmap some_map {
            field my_field { sw = rw; hw = r; };
            reg my_reg { my_field a; };
            regfile my_regfile { my_reg b; };
            addrmap my_map { my_regfile c; };
            my_map d;
          };
        RDL

        addrmap = addrmap.instances[0]
        assert_property_value(addrmap, :name, 'd')

        regfile = addrmap.instances[0]
        assert_property_value(regfile, :name, 'c')

        reg = regfile.instances[0]
        assert_property_value(reg, :name, 'b')

        field = reg.instances[0]
        assert_property_value(field, :name, 'a')
      end

      def test_field_instance_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              field { sw = rw; hw = r; } a;
            };
          RDL
          "field instance not allowed in addrmap"
        )
      end
    end
  end
end
