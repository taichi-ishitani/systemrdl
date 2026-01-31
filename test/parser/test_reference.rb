# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestReferecne < TestCase
      def test_instance_ref
        code = 'a'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = 'a[0]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '0')))
          ),
          code
        )

        code = 'a[0][1]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '0')), s(:array, s(:number, '1')))
          ),
          code
        )

        code = 'regA.a'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regA')),
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = 'regA[0].a[1]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '0'))),
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '1')))
          ),
          code
        )

        code = 'regA[0][1].a[2][3]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '0')), s(:array, s(:number, '1'))),
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '2')), s(:array, s(:number, '3')))
          ),
          code
        )

        code = 'regFA.regA.a'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regFA')),
            s(:instance_ref_element, s(:id, 'regA')),
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = 'regFA[0].regA[1].a[2]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regFA'), s(:array, s(:number, '0'))),
            s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '1'))),
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '2')))
          ),
          code
        )

        code = 'regFA[0][1].regA[2][3].a[4][5]'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'regFA'), s(:array, s(:number, '0')), s(:array, s(:number, '1'))),
            s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '2')), s(:array, s(:number, '3'))),
            s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '4')), s(:array, s(:number, '5')))
          ),
          code
        )
      end

      def test_prop_ref
        code = 'a->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'a'))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'a[0]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '0')))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'a[0][1]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '0')), s(:array, s(:number, '1')))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regA.a->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regA')),
              s(:instance_ref_element, s(:id, 'a'))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regA[0].a[1]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '0'))),
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '1')))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regA[0][1].a[2][3]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '0')), s(:array, s(:number, '1'))),
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '2')), s(:array, s(:number, '3')))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regFA.regA.a->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regFA')),
              s(:instance_ref_element, s(:id, 'regA')),
              s(:instance_ref_element, s(:id, 'a'))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regFA[0].regA[1].a[2]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regFA'), s(:array, s(:number, '0'))),
              s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '1'))),
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '2')))
            ),
            s(:id, 'b')
          ),
          code
        )

        code = 'regFA[0][1].regA[2][3].a[4][5]->b'
        assert_parses_expression(
          s(:prop_ref,
            s(:instance_ref,
              s(:instance_ref_element, s(:id, 'regFA'), s(:array, s(:number, '0')), s(:array, s(:number, '1'))),
              s(:instance_ref_element, s(:id, 'regA'), s(:array, s(:number, '2')), s(:array, s(:number, '3'))),
              s(:instance_ref_element, s(:id, 'a'), s(:array, s(:number, '4')), s(:array, s(:number, '5')))
            ),
            s(:id, 'b')
          ),
          code
        )
      end
    end
  end
end
