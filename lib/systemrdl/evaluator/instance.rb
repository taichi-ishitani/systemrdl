# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Instance
      def initialize(definition, parent, name, array_info, token_range)
        @definition = definition
        @parent = parent
        @name = name
        @array_info = array_info
        @token_range = token_range
        @properties = []
        @instances = []
      end

      attr_reader :definition
      attr_reader :parent
      attr_reader :name
      attr_reader :array_info
      attr_reader :token_range
      attr_reader :properties
      attr_reader :instances

      def root?
        layer == :root
      end

      def addrmap?
        layer == :addrmap
      end

      def regfile?
        layer == :regfile
      end

      def reg?
        layer == :reg
      end

      def field?
        layer == :field
      end

      def array?
        !array_info.nil?
      end

      def array_indices
        array_info&.indices
      end

      def array_sizes
        array_info&.sizes
      end

      def first_element?
        !array? || array_info.first
      end

      def last_element?
        !array? || array_info.last
      end

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

      def finalize
        @definition.finalize(self)
        @instances.each(&:finalize)
      end
    end
  end
end
