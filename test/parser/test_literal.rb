# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL::Parser
  class TestLiteral < TestCase
    def test_boolean
      assert_parses(s(:boolean, 'true'), 'true', test: true)
      assert_parses(s(:boolean, 'false'), 'false', test: true)
    end
  end
end
