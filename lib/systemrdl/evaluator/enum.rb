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
        width = enum.members.filter_map { |m| m.value.width }.max || 64
        enum.members.each { |m| m.apply_width(width) }
      end
    end

    class EnumMemberDef
      include Common

      def initialize(name, default_value, prop_assignments, token_range)
        super(token_range)
        @name = name
        @default_value = default_value
        @prop_assignments = prop_assignments
      end

      def evaluate(instance, enum, **optargs)
        value =
          if @default_value
            @default_value.evaluate(instance, **optargs)
          elsif (last_value = enum.members.last&.value)
            Value.new(last_value.value + 1, :bit, nil, token_range)
          else
            Value.new(0, :bit, nil, token_range)
          end

        # TODO
        # check value type/duplication

        member = EnumMember.new(@name.to_sym, value, enum, token_range)
        eval_prop(member, **optargs)

        enum.members << member
      end

      private

      def eval_prop(member, **optargs)
        BuiltinProperties.init_properties(:enum, member)
        @prop_assignments&.each do |prop|
          prop.evaluate(member, **optargs)
        end
      end
    end
  end
end
