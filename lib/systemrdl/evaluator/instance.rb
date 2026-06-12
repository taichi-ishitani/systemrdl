# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Instance
      def initialize(definition, parent, name)
        @definition = definition
        @parent = parent
        @name = name
        @properties = []
        @instances = []
      end

      attr_reader :definition
      attr_reader :parent
      attr_reader :name
      attr_reader :properties
      attr_reader :instances

      def property(name)
        properties.find { |prop| prop.name == name }
      end

      def property_value(name)
        property(name).value
      end

      def validate
        @definition.validate(self)
        @instances.each(&:revalidate)
      end

      def revalidate
        @definition.revalidate(self)
        @instances.each(&:revalidate)
      end
    end
  end
end
