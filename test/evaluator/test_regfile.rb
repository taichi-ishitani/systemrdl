# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegFile < TestCase
      def test_regfile_without_structural_component_instance_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
                name = "my regfile";
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
                reg my_reg {
                  field { sw = rw; hw = r; } a;
                };
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )
      end

      def test_range_for_regfile_instance_is_rejected
        skip 'not implemented yet'
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_addrmap {
              regfile {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a[0:0];
            };
          RDL
          'range not allowed for regfile instance'
        )
      end

      def test_address_stride_for_scalar_regfile_instance_is_rejected
        skip 'not implemented yet'
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_addrmap {
              regfile {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a += 0x4;
            };
          RDL
          'address stride not allowed for scalar regfile instance'
        )
      end
    end
  end
end
