# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Enum < Type::Base
      include RaiseEvaluationError

      def initialize(name, component_def, token_range)
        super()
        @name = name
        @members = []
        @component_def = component_def
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :width
      attr_reader :members
      attr_reader :component_def
      attr_reader :token_range

      def kind
        :enum
      end

      def to_s
        full_name
      end

      def cast(value, target, token_range)
        if target.kind in :bit | :boolean
          value.value.value.cast(target, token_range || value.token_range)
        else
          super
        end
      end

      def full_name
        component_def
          .upper_layers(include_root: false, include_self: true)
          .map(&:id)
          .then { |names| names << name }
          .join('::')
      end

      def apply_width
        @width = @members.filter_map { |m| m.value.type.width }.max || 64
        @members.each { |m| check_member_width(m) }
      end

      def to_value(token_range)
        Value.new(self, Type.enum_ref, token_range)
      end

      private

      def check_member_width(member)
        return if member.value.type.width

        value = member.value.value
        return if (0...(2**@width)).include?(value)

        message = "enum member value out of range: #{member.name} (value #{value} width #{@width})"
        raise_evaluation_error message, member.token_range
      end
    end

    class EnumMember
      include PropertyAccessor

      def initialize(name, enum, value, token_range)
        @name = name
        @enum = enum
        @value = value
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :value
      attr_reader :enum
      attr_reader :token_range

      def component_def
        enum.component_def
      end

      def scoped_name
        [enum.name, name].join('::')
      end
    end

    class EnumDef
      include Common

      def initialize(name, entries, token_range)
        super(token_range)
        @name = name
        @entries = entries
      end

      def connect(parent, component)
        super
        @entries.each { |entry| entry.connect(self, component) }
      end

      def evaluate(instance, **optargs)
        enum = Enum.new(@name.to_sym, @component, token_range)
        @entries.each do |entry|
          entry.evaluate(instance, enum, **optargs)
        end

        enum.apply_width
        @component.add_type(enum)
      end
    end

    class EnumMemberDef
      include Common

      def initialize(name, value, prop_assignments, token_range)
        super(token_range)
        @name = name
        @value = value
        @prop_assignments = prop_assignments
      end

      attr_reader :name

      def evaluate(instance, enum, **optargs)
        name = @name.to_sym
        check_member_name(enum, name, @name.token_range)

        value = eval_member_value(enum, name, instance, **optargs)
        check_member_value(enum, name, value, (@value || @name).token_range)

        member = EnumMember.new(name, enum, value, token_range)
        eval_prop(member, **optargs)

        enum.members << member
      end

      private

      def check_member_name(enum, name, token_range)
        return if enum.members.none? { |m| m.name == name }

        message = "duplicated enum member: #{name}"
        raise_evaluation_error message, token_range
      end

      def eval_member_value(enum, name, instance, **optargs)
        if @value
          eval_explicit_member_value(name, instance, **optargs)
        elsif (last_value = enum.members.last&.value)
          Value.new(last_value.value + 1, Type.unsized_bit, token_range)
        else
          Value.new(0, Type.unsized_bit, token_range)
        end
      end

      def eval_explicit_member_value(name, instance, **optargs)
        value = @value.evaluate(instance, **optargs)
        value.coerce([Type.unsized_bit]) do |_, type|
          message = "non integral enum member value: #{name} (#{type})"
          raise_evaluation_error message, @value.token_range
        end
      end

      def check_member_value(enum, name, value, token_range)
        return if enum.members.none? { |m| m.value.value == value.value }

        message = "duplicated enum member value: #{name} (#{value})"
        raise_evaluation_error message, token_range
      end

      def eval_prop(member, **optargs)
        BuiltinProperties.init_properties(:enum, member)
        @prop_assignments&.each do |prop|
          prop.evaluate(member, **optargs)
        end
      end
    end
  end
end
