# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(instance, name, types, ref_target, dynamic_assign, value)
        @instance = instance
        @name = name
        @types = types
        @ref_target = ref_target
        @dynamic_assign = dynamic_assign
        @value = value
      end

      attr_reader :name
      attr_reader :types
      attr_reader :value

      def to_value(token_range)
        Value.new(self, :property_reference, nil, token_range)
      end

      def full_name
        [@instance.full_name, name].join('.')
      end

      def assign(value)
        @value = value
      end
    end

    class PropertyDefinition
      def initialize(name)
        @name = name
        yield(self)
      end

      attr_reader :name
      attr_accessor :targets
      attr_accessor :types
      attr_accessor :ref_target
      attr_accessor :dynamic_assign
      attr_accessor :default_value

      def target?(instance)
        return false if instance.root?

        targets.nil? || targets.include?(instance.layer)
      end

      def create(instance)
        value = eval_value(instance)
        Property.new(instance, name, types, ref_target, dynamic_assign, value)
      end

      private

      def eval_value(instance)
        value =
          if default_value.is_a?(Proc)
            default_value.call(instance)
          else
            default_value
          end

        return if value.nil?

        create_value(value)
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
