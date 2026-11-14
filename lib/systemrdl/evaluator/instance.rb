# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Instance
      include RaiseEvaluationError
      include PropertyAccessor

      def initialize(component_def, parent, name, token_range)
        @component_def = component_def
        @parent = parent
        @name = name
        @params = []
        @instances = []
        @types = {}
        @default_properties = {}
        @token_range = token_range
      end

      attr_reader :component_def
      attr_reader :parent
      attr_reader :name
      attr_reader :params
      attr_reader :array_info
      attr_reader :token_range
      attr_reader :instances

      def to_value(token_range)
        Value.new(self, Type.inst_ref(layer), token_range)
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
        component_def.layer
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

      def mem?
        layer == :mem
      end

      def reg?
        layer == :reg
      end

      def field?
        layer == :field
      end

      def structural_component?
        addrmap? || regfile? || mem? || reg? || field?
      end

      def find_addrmap
        if RUBY_VERSION >= '4.0'
          upper_instances(include_root: false, include_self: true).rfind(&:addrmap?)
        else
          upper_instances(include_root: false, include_self: true).reverse_each.find(&:addrmap?)
        end
      end

      def array?
        false
      end

      def elements
        [*@params, *@instances]
      end

      def add_instance(instance)
        @instances << instance
      end

      def add_type(type)
        check_type_identifier(type)

        @types[type.name] = type
      end

      def type(name)
        @types[name]
      end

      def types
        @types.values
      end

      def add_default_property(name, value, token_range)
        if @default_properties.key?(name)
          message = "#{name} already assigned in this scope"
          raise_evaluation_error message, token_range
        end

        @default_properties[name] = value
      end

      def clear_default_properties
        @default_properties.clear
      end

      def default_property(name)
        @default_properties[name]
      end

      def validate
        @component_def.validate(self)
        @instances.each(&:revalidate)
      end

      def revalidate
        @component_def.revalidate(self)
        @instances.each(&:revalidate)
      end

      def finalize
        @instances.each(&:finalize)
        @component_def.finalize(self)
      end

      private

      def check_type_identifier(type)
        return unless @types.key?(type.name) || component_def.component_name?(type.name)

        message = "duplicated type identifier: #{type.name}"
        raise_evaluation_error message, type.token_range
      end
    end
  end
end
