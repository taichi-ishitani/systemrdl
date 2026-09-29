# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(element, definition, value)
        @element = element
        @definition = definition
        @value = value
      end

      attr_reader :value

      def name
        @definition.name
      end

      def types
        @definition.types
      end

      def to_value(token_range)
        Value.new(self, :property_reference, nil, token_range)
      end

      def full_name
        [@element.full_name, name].join('.')
      end

      def ref_target?
        if @definition.ref_target.is_a?(Proc)
          instance_exec(&@definition.ref_target)
        else
          @definition.ref_target
        end
      end

      def dynamic_assign?
        @definition.dynamic_assign
      end

      def per_element_assign?
        @definition.per_element_assign
      end

      def assign(value)
        @value = value
        @assigned = true
      end

      def assigned?
        @assigned || false
      end

      private

      def set?
        return false if value.nil?

        value.value != false
      end
    end

    class PropertyDefinition
      def initialize(name)
        @name = name
        yield(self)
      end

      attr_reader :name
      attr_accessor :targets
      attr_accessor :exist
      attr_accessor :types
      attr_accessor :ref_target
      attr_accessor :dynamic_assign
      attr_accessor :per_element_assign
      attr_accessor :default_value

      def create(element_type, element)
        return unless target?(element_type) && exist?(element)

        value = eval_value(element)
        Property.new(element, self, value)
      end

      private

      def target?(element_type)
        targets.nil? || targets.include?(element_type)
      end

      def exist?(element)
        if @exist.is_a?(Proc)
          @exist.call(element)
        else
          @exist
        end
      end

      def eval_value(element)
        value = element.component_def.find_default_property(name)
        return value if value

        value =
          if default_value.is_a?(Proc)
            default_value.call(element)
          else
            default_value
          end

        return if value.nil?

        value.is_a?(Value) ? value : create_value(value)
      end

      def create_value(value)
        case types[0]
        when :longint then Value.new(value, :bit, 64, nil)
        when :boolean then Value.new(value, :boolean, 1, nil)
        else Value.new(value, types[0], nil, nil)
        end
      end
    end
  end
end
