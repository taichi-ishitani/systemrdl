# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestPropertyAssignment < TestCase
      def test_prop_assignment
        code = 'hw=w;'
        assert_parses_prop_assignment(
          assignment(id('hw'), access_type(:w)),
          code
        )

        code = 'default sw=rw;'
        assert_parses_prop_assignment(
          default_assignment(id('sw'), access_type(:rw)),
          code
        )

        code = 'rclr = false;'
        assert_parses_prop_assignment(
          assignment(id('rclr'), boolean(false)),
          code
        )

        code = 'rset;'
        assert_parses_prop_assignment(
          assignment(id('rset')),
          code
        )

        code = 'default woclr;'
        assert_parses_prop_assignment(
          default_assignment(id('woclr')),
          code
        )

        code = 'default woset = true;'
        assert_parses_prop_assignment(
          default_assignment(id('woset'), boolean(true)),
          code
        )

        code = 'name = "cplCode";'
        assert_parses_prop_assignment(
          assignment(id('name'), string('"cplCode"')),
          code
        )

        code = 'default fieldwidth = 4;'
        assert_parses_prop_assignment(
          default_assignment(id('fieldwidth'), number(4)),
          code
        )

        code = 'encode = myBitFieldEncoding;'
        assert_parses_prop_assignment(
          assignment(id('encode'), id(:myBitFieldEncoding)),
          code
        )

        code = 'default encode=color;'
        assert_parses_prop_assignment(
          default_assignment(id('encode'), id(:color)),
          code
        )

        code = 'precedence = sw;'
        assert_parses_prop_assignment(
          assignment(id('precedence'), precedence_type(:sw)),
          code
        )

        code = 'default precedence = hw;'
        assert_parses_prop_assignment(
          default_assignment(id('precedence'), precedence_type(:hw)),
          code
        )
      end

      def test_prop_modifier
        code = 'posedge intr;'
        assert_parses_prop_assignment(
          modifier('posedge', id(:intr)),
          code
        )

        code = 'default posedge intr;'
        assert_parses_prop_assignment(
          default_modifier('posedge', id(:intr)),
          code
        )

        code = 'negedge intr;'
        assert_parses_prop_assignment(
          modifier('negedge', id(:intr)),
          code
        )

        code = 'default negedge intr;'
        assert_parses_prop_assignment(
          default_modifier('negedge', id(:intr)),
          code
        )

        code = 'bothedge intr;'
        assert_parses_prop_assignment(
          modifier('bothedge', id(:intr)),
          code
        )

        code = 'default bothedge intr;'
        assert_parses_prop_assignment(
          default_modifier('bothedge', id(:intr)),
          code
        )

        code = 'level intr;'
        assert_parses_prop_assignment(
          modifier('level', id(:intr)),
          code
        )

        code = 'default level intr;'
        assert_parses_prop_assignment(
          default_modifier('level', id(:intr)),
          code
        )

        code = 'nonsticky intr;'
        assert_parses_prop_assignment(
          modifier('nonsticky', id(:intr)),
          code
        )

        code = 'default nonsticky intr;'
        assert_parses_prop_assignment(
          default_modifier('nonsticky', id(:intr)),
          code
        )
      end

      def test_post_prop_assignment
        code = 'a->hw=w;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'hw'), access_type(:w)),
          code
        )

        code = 'a->sw=rw;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'sw'), access_type(:rw)),
          code
        )

        code = 'a->rclr = false;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'rclr'), boolean(false)),
          code
        )

        code = 'a->rset;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'rset')),
          code
        )

        code = 'a->woclr;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'woclr')),
          code
        )

        code = 'a->woset = true;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'woset'), boolean(true)),
          code
        )

        code = 'a->name = "cplCode";'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'name'), string('"cplCode"')),
          code
        )

        code = 'a->fieldwidth = 4;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'fieldwidth'), number(4)),
          code
        )

        code = 'a->encode = myBitFieldEncoding;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'encode'), id(:myBitFieldEncoding)),
          code
        )

        code = 'a->encode=color;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'encode'), id(:color)),
          code
        )

        code = 'a->precedence = sw;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'precedence'), precedence_type(:sw)),
          code
        )

        code = 'a->precedence = hw;'
        assert_parses_prop_assignment(
          post_assignment(reference('a', 'precedence'), precedence_type(:hw)),
          code
        )
      end

      def assignment(property, value = nil)
        s(:prop_assignment, *[property, value].compact)
      end

      def default_assignment(property, value = nil)
        s(:default_prop_assignment, *[property, value].compact)
      end

      def modifier(modifier, property)
        s(:prop_modifier, modifier, property)
      end

      def default_modifier(modifier, property)
        s(:default_prop_modifier, modifier, property)
      end

      def post_assignment(property, value = nil)
        s(:post_prop_assignment, *[property, value].compact)
      end

      def id(name)
        s(:id, name.to_s)
      end

      def reference(instance_name, property_name)
        s(:prop_ref,
          s(:instance_ref, s(:instance_ref_element, id(instance_name))),
          id(property_name)
        )
      end

      def access_type(type)
        s(:access_type, type.to_s)
      end

      def precedence_type(type)
        s(:precedence_type, type.to_s)
      end

      def boolean(value)
        s(:boolean, value.to_s)
      end

      def string(value)
        s(:string, value)
      end

      def number(value)
        s(:number, value.to_s)
      end
    end
  end
end
