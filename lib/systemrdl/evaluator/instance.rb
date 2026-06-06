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

      attr_reader :parent
      attr_reader :name
      attr_reader :properties
      attr_reader :instances

      def property(name)
        properties.find { |prop| prop.name == name }
      end
    end
  end
end
