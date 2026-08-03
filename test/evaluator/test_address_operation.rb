# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddressOperation < TestCase
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

          regfiles = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } a;
              } a @#{addresses[0]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } b;
              } b @#{addresses[1]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } c;
              } c @#{addresses[2]};
            };
          RDL

          assert_value(addresses[0], regfiles[0].address)
          assert_value(addresses[1], regfiles[1].address)
          assert_value(addresses[2], regfiles[2].address)
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

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  regfile {
                    reg {
                      regwidth = #{width};
                      accesswidth = #{width};
                      field { sw = r; hw = r; } a;
                    } a;
                  } a @#{address};
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
              } a[1] += #{strides[0]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } b[1] += #{strides[1]};
              reg {
                regwidth = #{width};
                accesswidth = #{width};
                field { sw = rw; hw = r; } a;
              } c[1] += #{strides[2]};
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
              } a[1] += #{strides[0]};
              a->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } b[1] += #{strides[1]};
              b->accesswidth = #{width};
              reg {
                regwidth = #{width};
                accesswidth = 8;
                field { sw = rw; hw = r; } a;
              } c[1] += #{strides[2]};
              c->accesswidth = #{width};
            };
          RDL

          assert_value(strides[0], regs[0].stride)
          assert_value(strides[1], regs[1].stride)
          assert_value(strides[2], regs[2].stride)

          regfiles = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } a;
              } a[1] += #{strides[0]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } b;
              } b[1] += #{strides[1]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } c;
              } c[1] += #{strides[2]};
            };
          RDL

          assert_value(strides[0], regfiles[0].stride)
          assert_value(strides[1], regfiles[1].stride)
          assert_value(strides[2], regfiles[2].stride)
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
                  } a[1] += #{stride};
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
                  } a[1] += #{stride};
                  a->accesswidth = #{width};
                };
              RDL
              "stride not aligned to accesswidth: stride 0x#{stride.to_s(16)} accesswidth #{width}"
            )

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  regfile {
                    reg {
                      regwidth = #{width};
                      accesswidth = #{width};
                      field { sw = r; hw = r; } a;
                    } a;
                  } a[1] += #{stride};
                };
              RDL
              "stride not aligned to accesswidth: stride 0x#{stride.to_s(16)} accesswidth #{width}"
            )
          end
        end
      end

      def test_stride_less_than_size_is_rejected
        [[2, 1], [4, 2], [8, 4], [16, 8]].each do |(size, stride)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{size * 8};
                  accesswidth = 8;
                  field { sw = r; hw = r; } a;
                } a[2] += #{stride};
              };
            RDL
            "stride less than reg size: stride 0x#{stride.to_s(16)} size #{size}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                regfile {
                  reg {
                    regwidth = #{size * 8};
                    accesswidth = 8;
                    field { sw = r; hw = r; } a;
                  } a;
                } a[2] += #{stride};
              };
            RDL
            "stride less than regfile size: stride 0x#{stride.to_s(16)} size #{size}"
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

          regfiles = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } a;
              } a %= #{alignments[0]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } b;
              } b %= #{alignments[1]};
              regfile {
                reg {
                  regwidth = #{width};
                  accesswidth = #{width};
                  field { sw = rw; hw = r; } a;
                } c;
              } c %= #{alignments[2]};
            };
          RDL

          assert_value(alignments[0], regfiles[0].alignment)
          assert_value(alignments[1], regfiles[1].alignment)
          assert_value(alignments[2], regfiles[2].alignment)
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

            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  regfile {
                    reg {
                      regwidth = #{width};
                      accesswidth = #{width};
                      field { sw = r; hw = r; } a;
                    } a;
                  } a %= #{alignment};
                };
              RDL
              "alignment not aligned to accesswidth: alignment 0x#{alignment.to_s(16)} accesswidth #{width}"
            )
          end
        end
      end

      def test_alignment_must_be_positive
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

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              regfile {
                reg {
                  regwidth = 32;
                  field { sw = r; hw = r; } a;
                } a;
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

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              regfile {
                reg {
                  regwidth = 32;
                  field { sw = r; hw = r; } a;
                } a;
              } a @0x0 %= 0x4;
            };
          RDL
          "@ and %= address operations are mutually exclusive"
        )
      end
    end
  end
end
