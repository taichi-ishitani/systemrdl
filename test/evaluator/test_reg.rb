# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestReg < TestCase
      def test_property_initialization
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            reg {} my_reg;
          };
        RDL

        assert_property(reg, :name, [:string], value: 'my_reg')
        assert_property(reg, :desc, [:string], value: '')
        assert_property(reg, :regwidth, [:longint], value: 32)
        assert_property(reg, :accesswidth, [:longint], value: 32)
        assert_property(reg, :errextbus, [:boolean], value: false)
        # todo
        # assert_property(reg, :intr)
        # assert_property(reg, :halt)
        assert_property(reg, :shared, [:boolean], value: false)
      end

      def test_array_instances
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap some_reg {
            reg {
              field { sw = rw; hw = r; } a;
            } a[1];
            reg {
              field { sw = rw; hw = r; } a;
            } b[1][2];
            reg {
              field { sw = rw; hw = r; } a;
            } c[1][2][3];
            reg {
              field { sw = rw; hw = r; } a;
            } d;
          };
        RDL

        assert_equal([0], regs[0].array_indices)
        assert_equal([1], regs[0].array_sizes)
        assert(regs[0].array?)

        [[0, 0], [0, 1]].each.with_index(1) do |indices, i|
          assert_equal(indices, regs[i].array_indices)
          assert_equal([1, 2], regs[i].array_sizes)
          assert(regs[i].array?)
        end

        [
          [0, 0, 0], [0, 0, 1], [0, 0, 2],
          [0, 1, 0], [0, 1, 1], [0, 1, 2]
        ].each.with_index(3) do |indices, i|
          assert_equal(indices, regs[i].array_indices)
          assert_equal([1, 2, 3], regs[i].array_sizes)
          assert(regs[i].array?)
        end

        assert_nil(regs[9].array_indices)
        assert_nil(regs[9].array_sizes)
        refute(regs[9].array?)
      end

      def test_reference_to_array_instance_element
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap some_reg {
            reg {
              regwidth = 32;
              field { sw = rw; hw = r; } a;
            } a[2];
            a[0]->accesswidth = 8;
            a[1]->accesswidth = 16;

            reg {
              regwidth = 32;
              field { sw = rw; hw = r; } a;
            } b[1][2];
            b[0][0]->accesswidth = 8;
            b[0][1]->accesswidth = 16;
          };
        RDL

        assert_property_value(regs[0], :accesswidth, 8)
        assert_property_value(regs[1], :accesswidth, 16)
        assert_property_value(regs[2], :accesswidth, 8)
        assert_property_value(regs[3], :accesswidth, 16)
      end

      def test_array_size_must_be_positive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a[0];
            };
          RDL
          "array size must be positive"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a[1][0];
            };
          RDL
          "array size must be positive"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a[1][2][0];
            };
          RDL
          "array size must be positive"
        )
      end

      def test_implicit_bit_allocation
        ['rw', 'r', 'w'].zip(['rw', 'r', 'w']).each do |accesses|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a;
                field { sw = #{accesses[1]}; hw = r; } b;
                field { sw = #{accesses[0]}; hw = r; } c[16:16];
                field { sw = #{accesses[1]}; hw = r; } d;
              } my_reg;
            };
          RDL

          assert_value(1, fields[1].lsb)
          assert_value(1, fields[1].msb)
          assert_value(17, fields[3].lsb)
          assert_value(17, fields[3].msb)
        end
      end

      def test_overlapping_fields_are_rejected
        [:rw, :rw1, :r, :w, :w1].product([:rw, :rw1, :r, :w, :w1]).each do |accesses|
          next if accesses in [:r, :w] | [:r, :w1] | [:w, :r] | [:w1, :r]

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[4:3];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[6:5];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[8:7];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )
        end
      end

      def test_overlapping_ro_wo_fields_are_allowed
        [[:r, :w], [:r, :w1], [:w, :r], [:w1, :r]].each do |accesses|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[4:3];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(3, fields[1].lsb);
          assert_value(4, fields[1].msb);

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[6:5];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(5, fields[1].lsb);
          assert_value(6, fields[1].msb);

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[8:7];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(7, fields[1].lsb);
          assert_value(8, fields[1].msb);
        end
      end

      def test_power_of_2_regwidth_is_accepted
        [8, 16, 32, 64, 128].each do |width|
          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                field { sw = rw; hw = r; } a;
              } my_reg;
            };
          RDL

          assert_property_value(regs[0], :regwidth, width)
        end
      end

      def test_non_power_of_2_regwidth_is_rejected
        [7, 9, 15, 17, 31, 33, 63, 65, 127, 129].each do |width|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a;
                } my_reg;
              };
            RDL
            "regwidth must be a power of 2: #{width}"
          )
        end
      end

      def test_field_out_of_register
        [8, 16, 32, 64, 128].each do |width|
          msb = width
          lsb = width - 1
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{msb}:#{lsb}];
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )

          msb = width
          lsb = msb
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{msb}:#{lsb}];
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{width - 1}:0];
                  field { sw = rw; hw = r; } b;
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )
        end
      end

      def test_regwidth_forces_default_value_of_accesswidth
        [8, 16, 32, 64, 128].each do |width|
          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                field { sw = rw; hw = r; } a;
              } my_reg;
            };
          RDL

          assert_property_value(regs[0], :accesswidth, width)
        end
      end

      def test_power_of_2_accesswidth_is_accepted
        [8, 16, 32, 64, 128].each do |width|
          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = 128;
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                regwidth = 128;
                field { sw = rw; hw = r; } b;
              } b;
              b->accesswidth = #{width};
            };
          RDL

          assert_property_value(regs[0], :accesswidth, width)
          assert_property_value(regs[1], :accesswidth, width)
        end
      end

      def test_non_power_of_2_accesswidth_is_rejected
        [7, 9, 15, 17, 31, 33, 63, 65, 127].each do |width|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = 128;
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } a;
              };
            RDL
            "accesswidth must be a power of 2: #{width}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = 128;
                  field { sw = rw; hw = r; } a;
                } a;
                a->accesswidth = #{width};
              };
            RDL
            "accesswidth must be a power of 2: #{width}"
          )
        end
      end

      def test_accesswidth_exceeds_regwidth
        [[8, 16], [16, 32], [32, 64], [64, 128]].each do |(regwidth, accesswidth)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  accesswidth = #{accesswidth};
                  regwidth = #{regwidth};
                  field { sw = rw; hw = r; } a;
                } a;
              };
            RDL
            "accesswidth exceeds regwidth: accesswidth = #{accesswidth} regwidth = #{regwidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  field { sw = rw; hw = r; } a;
                } a;
                a->accesswidth = #{accesswidth};
              };
            RDL
            "accesswidth exceeds regwidth: accesswidth = #{accesswidth} regwidth = #{regwidth}"
          )
        end
      end

      def test_address_aligned_to_accesswidth_is_allowed
        [8, 16, 32, 64, 128].each do |width|
          addresses = Array.new(3) { |i| i * (width / 8) }

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } a @#{addresses[0]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } b @#{addresses[1]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } c @#{addresses[2]};
            };
          RDL

          assert_value(addresses[0], regs[0].address)
          assert_value(addresses[1], regs[1].address)
          assert_value(addresses[2], regs[2].address)

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } a @#{addresses[0]};
              a->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } b @#{addresses[1]};
              b->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } c @#{addresses[2]};
              c->accesswidth = #{width};
            };
          RDL

          assert_value(addresses[0], regs[0].address)
          assert_value(addresses[1], regs[1].address)
          assert_value(addresses[2], regs[2].address)
        end
      end

      def test_address_not_aligned_to_accesswidth_is_rejected
        [16, 32, 64, 128].each do |width|
          [(width / 8) + 1, (width / 4) - 1, (width / 4) + 1].each do |address|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = #{width};
                    field { sw = r; hw = r; } a;
                  } a @#{address};
                };
              RDL
              "address not aligned to accesswidth: address 0x#{address.to_s(16)} accesswidth #{width}"
            )

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = 8;
                    field { sw = r; hw = r; } a;
                  } a @#{address};
                  a->accesswidth = #{width};
                };
              RDL
              "address not aligned to accesswidth: address 0x#{address.to_s(16)} accesswidth #{width}"
            )
          end
        end
      end

      def test_stride_aligned_to_accesswidth_is_allowed
        [8, 16, 32, 64, 128].each do |width|
          strides = Array.new(3) { |i| (i + 1) * (width / 8) }

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } a += #{strides[0]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } b += #{strides[1]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } c += #{strides[2]};
            };
          RDL

          assert_value(strides[0], regs[0].stride)
          assert_value(strides[1], regs[1].stride)
          assert_value(strides[2], regs[2].stride)

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } a += #{strides[0]};
              a->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } b += #{strides[1]};
              b->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } c += #{strides[2]};
              c->accesswidth = #{width};
            };
          RDL

          assert_value(strides[0], regs[0].stride)
          assert_value(strides[1], regs[1].stride)
          assert_value(strides[2], regs[2].stride)
        end
      end

      def test_stride_not_aligned_to_accesswidth_is_rejected
        [16, 32, 64, 128].each do |width|
          [(width / 8) + 1, (width / 4) - 1, (width / 4) + 1].each do |stride|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = #{width};
                    field { sw = r; hw = r; } a;
                  } a += #{stride};
                };
              RDL
              "stride not aligned to accesswidth: stride 0x#{stride.to_s(16)} accesswidth #{width}"
            )

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = 8;
                    field { sw = r; hw = r; } a;
                  } a += #{stride};
                  a->accesswidth = #{width};
                };
              RDL
              "stride not aligned to accesswidth: stride 0x#{stride.to_s(16)} accesswidth #{width}"
            )
          end
        end
      end

      def test_stride_less_than_regwidth_is_rejected
        [[16, 8, 1], [32, 16, 2], [64, 32, 4], [128, 64, 8]].each do |(regwidth, accesswidth, stride)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; } a;
                } a += #{stride};
              };
            RDL
            "stride less than reg size: stride 0x#{stride.to_s(16)} reg size #{regwidth / 8}"
          )
        end
      end

      def test_alignment_aligned_to_accesswidth_is_allowed
        [8, 16, 32, 64, 128].each do |width|
          alignments = Array.new(3) { |i| (i + 1) * (width / 8) }

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } a %= #{alignments[0]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } b %= #{alignments[1]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } c %= #{alignments[2]};
            };
          RDL

          assert_value(alignments[0], regs[0].alignment)
          assert_value(alignments[1], regs[1].alignment)
          assert_value(alignments[2], regs[2].alignment)

          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } a %= #{alignments[0]};
              a->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } b %= #{alignments[1]};
              b->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } c %= #{alignments[2]};
              c->accesswidth = #{width};
            };
          RDL

          assert_value(alignments[0], regs[0].alignment)
          assert_value(alignments[1], regs[1].alignment)
          assert_value(alignments[2], regs[2].alignment)
        end
      end

      def test_alignment_not_aligned_to_accesswidth_is_rejected
        [16, 32, 64, 128].each do |width|
          [(width / 8) + 1, (width / 4) - 1, (width / 4) + 1].each do |alignment|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = #{width};
                    field { sw = r; hw = r; } a;
                  } a %= #{alignment};
                };
              RDL
              "alignment not aligned to accesswidth: alignment 0x#{alignment.to_s(16)} accesswidth #{width}"
            )

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    regwidth = #{width};
                    accesswidth = 8;
                    field { sw = r; hw = r; } a;
                  } a %= #{alignment};
                  a->accesswidth = #{width};
                };
              RDL
              "alignment not aligned to accesswidth: alignment 0x#{alignment.to_s(16)} accesswidth #{width}"
            )
          end
        end
      end

      def test_alignmet_must_be_positive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                regwidth = 32;
                field { sw = r; hw = r; } a;
              } a %= 0;
            };
          RDL
          "alignment must be positive"
        )
      end

      def test_address_alignment_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                regwidth = 32;
                field { sw = r; hw = r; } a;
              } a @0x0 %= 0x4;
            };
          RDL
          "@ and %= address operations are mutually exclusive"
        )
      end

      def test_writable_fields_spanning_sub_word_boundary_are_rejected
        [[16, 8], [32, 16], [64, 32], [128, 64]].product(['rw', 'w']).each do |(regwidth, accesswidth), sw|
          lsb = accesswidth - 1
          msb = accesswidth

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = #{sw}; hw = r; } a[#{msb}:#{lsb}];
                } a;
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  field { sw = #{sw}; hw = r; } a[#{msb}:#{lsb}];
                } a;
                a->accesswidth = #{accesswidth};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; } a[#{msb}:#{lsb}];
                } a;
                a.a->sw = #{sw};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )
        end
      end

      def test_ro_fields_with_side_effect_spanning_sub_word_boundary_are_rejected
        [
          [16, 8], [32, 16], [64, 32], [128, 64]
        ].product(['rclr', 'rset', 'ruser']).each do |(regwidth, accesswidth), onread|
          lsb = accesswidth - 1
          msb = accesswidth

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; onread = #{onread}; } a[#{msb}:#{lsb}];
                } a;
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  field { sw = r; hw = r; onread = #{onread}; } a[#{msb}:#{lsb}];
                } a;
                a->accesswidth = #{accesswidth};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; } a[#{msb}:#{lsb}];
                } a;
                a.a->onread = #{onread};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          next if onread == 'ruser'

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; #{onread}; } a[#{msb}:#{lsb}];
                } a;
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  field { sw = r; hw = r; #{onread}; } a[#{msb}:#{lsb}];
                } a;
                a->accesswidth = #{accesswidth};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{regwidth};
                  accesswidth = #{accesswidth};
                  field { sw = r; hw = r; } a[#{msb}:#{lsb}];
                } a;
                a.a->#{onread};
              };
            RDL
            "field spanning sub-word boundary not allowed: bit position [#{msb}:#{lsb}] accesswidth #{accesswidth}"
          )
        end
      end

      def test_ro_fields_without_side_effect_spanning_sub_word_boundary_are_allowed
        [[16, 8], [32, 16], [64, 32], [128, 64]].each do |(regwidth, accesswidth)|
          lsb = accesswidth - 1
          msb = accesswidth

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{regwidth};
                accesswidth = #{accesswidth};
                field { sw = r; hw = r; } a[#{msb}:#{lsb}];
              } a;
            };
          RDL

          assert_value(lsb, fields[0].lsb);
          assert_value(msb, fields[0].msb);

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{regwidth};
                field { sw = r; hw = r; } a[#{msb}:#{lsb}];
              } a;
              a->accesswidth = #{accesswidth};
            };
          RDL

          assert_value(lsb, fields[0].lsb);
          assert_value(msb, fields[0].msb);
        end
      end

      def test_non_field_component_instances_are_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              reg {
                field { hw=r; } a;
              } a;
            };
            addrmap b_addrmap {
              reg {
                a_addrmap b;
              } b;
            };
          RDL
          "addrmap instance not allowed in reg"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              regfile a_regfile {
                reg {
                  field { hw=r; } a;
                } a;
              };
              reg {
                a_regfile b;
              } b;
            };
          RDL
          "regfile instance not allowed in reg"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              reg a_reg {
                field { hw=r; } a;
              };
              reg {
                a_reg b;
              } b;
            };
          RDL
          "reg instance not allowed in reg"
        )
      end

      def test_non_field_component_definitions_are_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                addrmap b_addrmap {
                  reg b_reg {
                    field b_field { hw = r; };
                  };
                };
              } a;
            };
          RDL
          'addrmap definition not allowed in reg'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                regfile b_regfile {
                  reg b_reg {
                    field b_field { hw = r; };
                  };
                };
              } a;
            };
          RDL
          'regfile definition not allowed in reg'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                reg b_reg {
                  field b_field { hw = r; };
                };
              } a;
            };
          RDL
          'reg definition not allowed in reg'
        )
      end
    end
  end
end
