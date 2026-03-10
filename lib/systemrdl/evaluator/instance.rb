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

      def add_child_instance(name)
        child = Instance.new(self, name)
        yield(child) if block_given?
        @instances << child
        child
      end
    end
  end
end
