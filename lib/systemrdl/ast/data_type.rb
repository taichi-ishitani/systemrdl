# frozen_string_literal: true

module SystemRDL
  module AST
    class DataType < Base
      def initialize(position, data_type)
        assign_properties(data_type: data_type)
        super(:data_type, position)
      end

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

      def data_type
        user_defined? && @data_type.id || @data_type
      end

      private

      def match_type?(type)
        @data_type == type
      end
    end
  end
end
