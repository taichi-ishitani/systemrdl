# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMap < TestCase
      def test_addrmap_instance_with_internal_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              addrmap my_map {
                reg { field { sw = rw; hw = r; } a; } a;
              };
              internal my_map a;
            };
          RDL
          'addrmap instance with internal not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              addrmap {
                reg { field { sw = rw; hw = r; } a; } a;
              } internal a;
            };
          RDL
          'addrmap instance with internal not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              internal addrmap {
                reg { field { sw = rw; hw = r; } a; } a;
              } a;
            };
          RDL
          'addrmap instance with internal not allowed'
        )
      end

      def test_addrmap_instance_with_external_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              addrmap my_map {
                reg { field { sw = rw; hw = r; } a; } a;
              };
              external my_map a;
            };
          RDL
          'addrmap instance with external not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              addrmap {
                reg { field { sw = rw; hw = r; } a; } a;
              } external a;
            };
          RDL
          'addrmap instance with external not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              external addrmap {
                reg { field { sw = rw; hw = r; } a; } a;
              } a;
            };
          RDL
          'addrmap instance with external not allowed'
        )
      end

      def test_instances_with_internal_in_addrmap_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            reg my_reg { field { sw = rw; hw = r; } a; };
            regfile my_regfile { my_reg a; };
            internal my_reg a;
            internal my_regfile b;
          };
        RDL

        refute(insts[0].external)
        refute(insts[1].external)
      end

      def test_instances_with_external_in_addrmap_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            reg my_reg { field { sw = rw; hw = r; } a; };
            regfile my_regfile { my_reg a; };
            external my_reg a;
            external my_regfile b;
          };
        RDL

        assert(insts[0].external)
        assert(insts[1].external)
      end

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

      def test_accesswidth
        addrmaps = evaluate(<<~'RDL').instances[0].instances
          addrmap my_addrmap {
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } a;
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
            } b;
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              addrmap {
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } b;
            } c;
          };
        RDL

        assert_equal(32, addrmaps[0].accesswidth)
        assert_equal(64, addrmaps[1].accesswidth)
        assert_equal(64, addrmaps[2].accesswidth)
      end

      def test_size
        addrmaps = evaluate(<<~'RDL').instances[0].instances
          addrmap my_addrmap {
            addressing = compact;

            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } a;
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
            } b;
            addrmap {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } c;
            addrmap {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a[3];
            } d;
            addrmap {
              addrmap {
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } e;
            addrmap {
              addrmap {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
              } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } f;
            addrmap {
              addrmap {
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } a[3];
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } g;
            addrmap {
              addrmap {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
              } a[3];
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } h;
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b @0xC;
            } i;
            addrmap {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a @0xC;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b @0x0;
            } j;
            addrmap {
              reg { regwidth = 128; field { sw = r; hw = r; } a; } a @0x0;
              reg { regwidth = 32 ; field { sw = w; hw = r; } b; } b @0x4;
            } k;
          };
        RDL

        [8, 16, 12, 24, 20, 16, 52, 48, 16, 16, 16].each_with_index do |size, i|
          assert_equal(size, addrmaps[i].size)
        end
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

      def test_alignment_is_not_inherited_from_upper_addrmap
        addrmap = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_addrmap {
            alignment = 8;
            addrmap {
              reg {
                regwidth = 32;
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                regwidth = 32;
                field { sw = rw; hw = r; } b;
              } b;
            } a;
          };
        RDL

        assert_property_value(addrmap, :alignment, nil)
        assert_value(0x04, addrmap.instances[1].address)
      end

      def test_addressing_is_not_inherited_from_upper_addrmap
        addrmap = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_addrmap {
            addressing = compact;
            addrmap {
              reg {
                regwidth = 32;
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                regwidth = 64;
                accesswidth = 32;
                field { sw = rw; hw = r; } b;
              } b;
            } a;
          };
        RDL

        assert_property_value(addrmap, :addressing, :regalign)
        assert_value(0x08, addrmap.instances[1].address)
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
