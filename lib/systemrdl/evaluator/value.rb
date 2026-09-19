# frozen_string_literal: true

module SystemRDL
  module Evaluator
    Value = Data.define(:value, :type, :width, :token_range) do
      def to_s
        value.to_s
      end

      def coerce(target_types, &iferror)
        if target_types.include?(type)
          self
        elsif match_integral_type?(target_types)
          cast_integral_value(target_types)
        else
          iferror.call
        end
      end

      private

      def match_integral_type?(target_types)
        integral_types = [:bit, :longint, :boolean]
        return false unless integral_types.include?(type)

        (integral_types & target_types).any?
      end

      def cast_integral_value(target_types)
        if target_types.include?(:bit)
          to_bit
        elsif target_types.include?(:longint)
          to_longint
        else
          to_boolean
        end
      end

      def to_bit
        return self if type == :bit

        if type == :longint
          Value.new(value, :bit, 64, token_range)
        elsif value
          Value.new(1, :bit, 1, token_range)
        else
          Value.new(0, :bit, 1, token_range)
        end
      end

      def to_longint
        return self if type == :longint

        if type == :bit
          v = value & 0xFFFF_FFFF_FFFF_FFFF
          Value.new(v, :longint, 64, token_range)
        elsif value
          Value.new(1, :longint, 64, token_range)
        else
          Value.new(0, :longint, 64, token_range)
        end
      end

      def to_boolean
        return self if type == :boolean

        Value.new(value != 0, :boolean, 1, token_range)
      end
    end

    Values = Data.define(:values, :token_range)
  end
end
