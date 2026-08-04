# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestArrayComponent < TestCase
      def test_array_instances
        test_codes = [
          <<~'RDL',
            addrmap top {
              reg my_reg {
                field { sw = rw; hw = r; } a;
              };
              my_reg a[1];
              my_reg b[1][2];
              my_reg c[1][2][3];
              my_reg d;
            };
          RDL
          <<~'RDL',
            addrmap top {
              regfile my_regfile {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              };
              my_regfile a[1];
              my_regfile b[1][2];
              my_regfile c[1][2][3];
              my_regfile d;
            };
          RDL
          <<~'RDL'
            addrmap top {
              addrmap my_addrmap {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              };
              my_addrmap a[1];
              my_addrmap b[1][2];
              my_addrmap c[1][2][3];
              my_addrmap d;
            };
          RDL
        ]

        test_codes.each do |code|
          insts = evaluate(code).instances[0].instances

          assert_equal([0], insts[0].array_indices)
          assert_equal([1], insts[0].array_sizes)
          assert(insts[0].array?)

          [[0, 0], [0, 1]].each.with_index(1) do |indices, i|
            assert_equal(indices, insts[i].array_indices)
            assert_equal([1, 2], insts[i].array_sizes)
            assert(insts[i].array?)
          end

          [
            [0, 0, 0], [0, 0, 1], [0, 0, 2],
            [0, 1, 0], [0, 1, 1], [0, 1, 2]
          ].each.with_index(3) do |indices, i|
            assert_equal(indices, insts[i].array_indices)
            assert_equal([1, 2, 3], insts[i].array_sizes)
            assert(insts[i].array?)
          end

          assert_nil(insts[9].array_indices)
          assert_nil(insts[9].array_sizes)
          refute(insts[9].array?)
        end
      end

      def test_range_is_rejected
        [[:reg, 'my_reg'], [:regfile, 'my_regfile'], [:addrmap, 'my_addrmap']].each do |(layer, comp)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap top {
                reg my_reg {
                  field { sw = rw; hw = r; } a;
                };
                regfile my_regfile {
                  my_reg a;
                };
                addrmap my_addrmap {
                  my_reg a;
                };
                #{comp} a[0:0];
              };
            RDL
            "range not allowed for #{layer} instance"
          )
        end
      end

      def test_address_stride_for_scalar_instance_is_rejected
        [[:reg, 'my_reg'], [:regfile, 'my_regfile'], [:addrmap, 'my_addrmap']].each do |(layer, comp)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap top {
                reg my_reg {
                  field { sw = rw; hw = r; } a;
                };
                regfile my_regfile {
                  my_reg a;
                };
                addrmap my_addrmap {
                  my_reg a;
                };
                #{comp} a += 0x4;
              };
            RDL
            "address stride not allowed for scalar #{layer} instance"
          )
        end
      end

      def test_array_size_must_be_positive
        defines = <<~'RDL'
          reg my_reg {
            field { sw = rw; hw = r; } a;
          };
          regfile my_regfile {
            my_reg a;
          };
          addrmap my_addrmap {
            my_reg a;
          };
        RDL

        ['my_reg', 'my_regfile'].each do |comp|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap top {
                #{defines}
                #{comp} a[0];
              };
            RDL
            "array size must be positive"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap top {
                #{defines}
                #{comp} a[1][0];
              };
            RDL
            "array size must be positive"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap top {
                #{defines}
                #{comp} a[1][2][0];
              };
            RDL
            "array size must be positive"
          )
        end
      end
    end
  end
end
