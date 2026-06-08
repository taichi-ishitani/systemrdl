# frozen_string_literal: true

module SystemRDL
  module Evaluator
    Value = Data.define(:value, :token_range) do
      def to_s
        value.to_s
      end
    end
  end
end
