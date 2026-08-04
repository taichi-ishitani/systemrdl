# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Instance
      def initialize(definition, parent, name, type, array_info, token_range)
        @definition = definition
        @parent = parent
        @name = name
        @type = type
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

      def to_value(token_range)
        Value.new(self, :"#{layer}_reference", nil, token_range)
      end

      def element_name
        return name.to_s unless array?

        array_info
          .indices
          .inject([name]) { |name_elements, index| name_elements << "[#{index}]" }
          .join
      end

      def full_name
        upper_instances(include_root: false, include_self: true).map(&:element_name).join('.')
      end

      def upper_instances(include_root: false, include_self: false)
        instances = (root? && []) || parent.upper_instances(include_root:, include_self: true)
        instances << self if (root? && include_root) || (!root? && include_self)
        instances
      end

      def layer
        definition.layer
      end

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

      def structural_component?
        addrmap? || regfile? || reg? || field?
      end

      def external?
        @type == :external
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
        property(name)&.value
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
        @instances.each(&:finalize)
        @definition.finalize(self)
      end
    end
  end
end
