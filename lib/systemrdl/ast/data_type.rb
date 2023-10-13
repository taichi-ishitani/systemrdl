# frozen_string_literal: true

module SystemRDL
  module AST
    class DataType < Base
      def initialize(data_type, type_symbol)
        assign_properties(data_type: type_symbol || to_symbol(data_type))
        super(:data_type, position || data_type)
      end

      attr_reader :data_type

      PRIMARY_TYPES = [
        :bit, :longint, :boolean, :string,
        :accesstype, :addressingtype, :onreadtype, :onwritetype
      ].freeze

      PRIMARY_TYPES.each do |type|
        define_method("#{type}?") do
          match_type?(type)
        end
      end

      def user_defined?
        PRIMARY_TYPES.none? { |type| match_type?(type) }
      end

      private

      def match_type?(type)
        @data_type == type
      end
    end
  end
end
