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
    end
  end
end
