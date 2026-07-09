# frozen_string_literal: true

module SystemRDL
  module Evaluator
    Value = Data.define(:value, :type, :width, :token_range) do
      def to_s
        value.to_s
      end
    end

    Values = Data.define(:values, :token_range)
  end
end
