# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestInstance < TestCase
      def test_recursive_instance_is_reject
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap some_map {
              regfile my_regfile {
                reg {
                  field { sw = rw; hw = r;} a;
                } a;
                my_regfile b;
              };
              my_regfile a;
            };
          RDL
          'recursive instance not allowed'
        )
      end
    end
  end
end
