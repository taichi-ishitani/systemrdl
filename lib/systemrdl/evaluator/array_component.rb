# frozen_string_literal: true

module SystemRDL
  module Evaluator
    ArrayInfo = Data.define(:indices, :sizes, :first, :last) do
      def n_elements
        sizes.inject(:*)
      end
    end

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

        index_list =
          sizes
            .map { |size| size.times.to_a }
            .then { |list| list[0].product(*list[1..]) }
        index_list.each.with_index(1) do |indices, i|
          info = ArrayInfo.new(indices, sizes, i == 1, i == index_list.size)
          yield(info)
        end
      end
    end
  end
end
