# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMap < TestCase
      def test_property_initialization
        addrmap = evaluate(<<~'RDL').instances[0]
          addrmap some_reg {};
        RDL

        assert_property(addrmap, :name, [:string], value: 'some_reg')
        assert_property(addrmap, :desc, [:string], value: '')
        assert_property(addrmap, :alignment, [:longint])
        assert_property(addrmap, :sharedextbus, [:boolean], value: false)
        assert_property(addrmap, :errextbus, [:boolean], value: false)
        assert_property(addrmap, :bigendian, [:boolean], value: false)
        assert_property(addrmap, :littleendian, [:boolean], value: false)
        assert_property(addrmap, :addressing, [:addressingtype], value: :regalign)
        assert_property(addrmap, :rsvdset, [:boolean], value: false)
        assert_property(addrmap, :rsvdsetX, [:boolean], value: false)
        assert_property(addrmap, :msb0, [:boolean], value: false)
        assert_property(addrmap, :lsb0, [:boolean], value: false)
      end

      def test_power_of_2_alignment_is_accepted
        [1, 2, 4, 8, 16, 32].each do |alignment|
          addrmap = evaluate(<<~RDL).instances[0]
            addrmap my_map {
              alignment = #{alignment};
              reg my_reg {
                field { sw = rw; hw = r; } my_field;
              };
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
                reg my_reg {
                  field { sw = rw; hw = r; } my_field;
                };
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
            reg a {
              field { sw = rw; hw = r; } a;
            };
          };
          addrmap b {
            bigendian;
            reg b {
              field { sw = rw; hw = r; } b;
            };
          };
          addrmap c {
            bigendian = false;
            littleendian = true;
            reg c {
              field { sw = rw; hw = r; } c;
            };
          };
          addrmap d {
            littleendian;
            reg d {
              field { sw = rw; hw = r; } d;
            };
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
              reg my_reg {
                field { sw = rw; hw = r; } my_field;
              };
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
            reg a {
              field { sw = rw; hw = r; } a;
            };
          };
          addrmap b {
            rsvdset;
            reg b {
              field { sw = rw; hw = r; } b;
            };
          };
          addrmap c {
            rsvdset = false;
            rsvdsetX = true;
            reg c {
              field { sw = rw; hw = r; } c;
            };
          };
          addrmap d {
            rsvdsetX;
            reg d {
              field { sw = rw; hw = r; } d;
            };
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
              reg my_reg {
                field { sw = rw; hw = r; } my_field;
              };
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
            reg a {
              field { sw = rw; hw = r; } a;
            };
          };
          addrmap b {
            msb0;
            reg b {
              field { sw = rw; hw = r; } b;
            };
          };
          addrmap c {
            msb0 = false;
            lsb0 = true;
            reg c {
              field { sw = rw; hw = r; } c;
            };
          };
          addrmap d {
            lsb0;
            reg d {
              field { sw = rw; hw = r; } d;
            };
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
              reg my_reg {
                field { sw = rw; hw = r; } my_field;
              };
            };
          RDL
          'msb0 and lsb0 properties are mutually exclusive'
        )
      end
    end
  end
end
