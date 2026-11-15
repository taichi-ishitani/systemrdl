# frozen_string_literal: true

module SystemRDL
  module Model
    class Enum
      include Common

      def initialize(enum, parent, model_map)
        super(enum, enum.name.to_s, parent, enum.token_range, model_map)
        @members = build_members(enum, model_map).freeze
        freeze
      end

      attr_reader :members

      def to_s
        "#{@name} (enum)"
      end

      def full_name
        [parent.full_name, name].reject(&:empty?).join('::')
      end

      def pretty_print(pp)
        pp.group(2, "#{self} {", '}') do
          @members.each do |member|
            pp.breakable
            pp.pp(member)
          end
        end
      end

      private

      def build_members(enum, model_map)
        enum.members.map { |member| EnumMember.new(member, self, model_map) }
      end
    end

    class EnumMember
      include Common

      def initialize(member, parent, model_map)
        super(member, member.name.to_s, parent, member.token_range, model_map)
        @properties = build_properties(member, model_map).freeze
        @value = member.value.value
        freeze
      end

      attr_reader :value

      def_property :display_name
      def_property :desc

      def to_s
        @name
      end

      def full_name
        "#{parent.full_name}::#{name}"
      end

      def pretty_print(pp)
        pp.group(2, "#{self} {", '}') do
          pp.breakable
          pp.pp(Value.new('value', @value, nil, nil))
          pp_properties(pp)
        end
      end
    end
  end
end
