# frozen_string_literal: true

module SystemRDL
  module Evaluator
    Value = Data.define(:value, :type, :token_range) do
      def update(**update_fields)
        update_values = to_h do |field, value|
          if update_fields.key?(field)
            [field, update_fields[field]]
          else
            [field, value]
          end
        end
        Value.new(**update_values)
      end

      def to_s
        value.to_s
      end

      def to_sym
        value.to_sym
      end

      def cast(target_type, token_range = self.token_range)
        type.cast(self, target_type, token_range)
      end

      def coerce(target_types, &iferror)
        target_types.each do |target_type|
          value = cast(target_type)
          return value if value
        end

        iferror&.call(target_types, type)
      end
    end

    Values = Data.define(:values, :token_range)
  end
end
