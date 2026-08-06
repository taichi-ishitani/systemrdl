# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(instance, definition, value)
        @instance = instance
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
        [@instance.full_name, name].join('.')
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

      def create(instance)
        return unless target?(instance) && exist?(instance)

        value = eval_value(instance)
        Property.new(instance, self, value)
      end

      private

      def target?(instance)
        return false if instance.root?

        targets.nil? || targets.include?(instance.layer)
      end

      def exist?(instance)
        if @exist.is_a?(Proc)
          @exist.call(instance)
        else
          @exist
        end
      end

      def eval_value(instance)
        value = instance.definition.find_default_property(name)
        return value if value

        value =
          if default_value.is_a?(Proc)
            default_value.call(instance)
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
