# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Instance
      def initialize(parent, name)
        @parent = parent
        @name = name
        @properties = []
        @instances = []
      end

      attr_reader :name
      attr_reader :properties
      attr_reader :instances
    end
  end
end
