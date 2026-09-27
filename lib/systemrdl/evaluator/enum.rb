# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Enum
      def initialize(name, token_range)
        @name = name
        @members = []
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :members
      attr_reader :token_range
    end

    class EnumMember
      def initialize(name, value, token_range)
        @name = name
        @value = value
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :value
      attr_reader :token_range

      def apply_width(width)
        @value = @value.update(width:)
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
        enum = Enum.new(@name.to_sym, token_range)
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

      def initialize(name, value, token_range)
        super(token_range)
        @name = name
        @value = value
      end

      def evaluate(instance, enum, **optargs)
        value =
          if @value
            @value.evaluate(instance, **optargs)
          elsif (last_value = enum.members.last&.value)
            Value.new(last_value.value + 1, :bit, nil, token_range)
          else
            Value.new(0, :bit, nil, token_range)
          end

        # TODO
        # check value type/duplication

        enum.members << EnumMember.new(@name.to_sym, value, token_range)
      end
    end
  end
end
