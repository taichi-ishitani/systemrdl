# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL::Parser
  class TestLiteral < TestCase
    def test_boolean
      assert_parses(s(:boolean, 'true'), 'true', test: true)
      assert_parses(s(:boolean, 'false'), 'false', test: true)
    end

    def test_string
      string = '""'
      assert_parses(s(:string, string), string, test: true)

      string = '"This is a string"'
      assert_parses(s(:string, string), string, test: true)

      string = "\"This is also \na string\""
      assert_parses(s(:string, string), string, test: true)
    end

    def test_string_with_escaped_quote
      string = '"This third string contains a \\"double quote\\""'
      assert_parses(s(:string, '"This third string contains a "double quote""'), string, test: true)
    end
  end
end
