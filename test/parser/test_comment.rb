# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestComment < TestCase
      def test_single_line_comment
        code = <<~'RDL'
          // leading comment
          a
        RDL
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = <<~'RDL'
          a // trailing comment
        RDL
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = <<~'RDL'
          a // comment
          . // comment
          b
        RDL
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a')),
            s(:instance_ref_element, s(:id, 'b'))
          ),
          code
        )
      end

      def test_block_comment
        code = '/* comment */ a'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = <<~'RDL'
          /*
           * multi-line
           * block comment
           */
          a
        RDL
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )

        code = 'a /* comment */ . /* comment */ b'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a')),
            s(:instance_ref_element, s(:id, 'b'))
          ),
          code
        )
      end

      def test_line_comment_inside_block_comment
        code = <<~'RDL'
          /* // this is part of the block comment
             still inside */
          a
        RDL
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )
      end

      def test_block_comment_not_nested
        code = '/* outer /* inner */ a'
        assert_parses_expression(
          s(:instance_ref,
            s(:instance_ref_element, s(:id, 'a'))
          ),
          code
        )
      end

      def test_unterminated_block_comment
        assert_raises_parse_error(
          '/* unterminated a',
          'unterminated block comment'
        )
      end
    end
  end
end
