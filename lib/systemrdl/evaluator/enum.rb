# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Enum
      def initialize(name, component_def, token_range)
        @name = name
        @members = []
        @component_def = component_def
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :members
      attr_reader :component_def
      attr_reader :token_range
    end

    class EnumMember
      include PropertyAccessor

      def initialize(name, value, enum, token_range)
        @name = name
        @value = value
        @enum = enum
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :value
      attr_reader :enum
      attr_reader :token_range

      def apply_width(width)
        @value = @value.update(width:)
      end

      def component_def
        enum.component_def
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
        apply_member_width(enum)

        @component.add_type(enum)
      end

      private

      def apply_member_width(enum)
        width = enum.members.filter_map { |member| member.value.width }.max || 64
        enum.members.each_with_index do |member, i|
          check_member_value_width(member, width, @entries[i].name.token_range)
          member.apply_width(width)
        end
      end

      def check_member_value_width(member, width, token_range)
        return if member.value.width

        value = member.value.value
        return if (0...(2**width)).include?(value)

        message = "enum member value out of range: #{member.name} (value #{value} width #{width})"
        raise_evaluation_error message, token_range
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

        member = EnumMember.new(name, value, enum, token_range)
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
          Value.new(last_value.value + 1, :bit, nil, token_range)
        else
          Value.new(0, :bit, nil, token_range)
        end
      end

      def eval_explicit_member_value(name, instance, **optargs)
        value = @value.evaluate(instance, **optargs)
        value.coerce([:bit]) do |_, type|
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
