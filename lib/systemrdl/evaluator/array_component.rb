# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module ArrayComponent
      private

      def eval_array(inst_values)
        array = inst_values[:array]
        return super unless array

        sizes = array.values.map do |size|
          next size.value if size.value > 0

          message = 'array size must be positive'
          raise_evaluation_error message, size.token_range
        end

        index_list = sizes.map { |size| size.times.to_a }
        index_list[0]
          .product(*index_list[1..])
          .each { |indices| yield(indices, sizes) }
      end
    end
  end
end
