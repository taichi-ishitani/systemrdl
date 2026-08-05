# frozen_string_literal: true

module SystemRDL
  module Evaluator
    ArrayInfo = Data.define(:id, :indices, :sizes, :first, :last) do
      def n_elements
        sizes.inject(:*)
      end
    end

    module ArrayComponent
      private

      def apply_array(instance, array_info)
        instance.array_info = array_info
      end

      def eval_array(inst_values)
        array = inst_values[:array]
        return super unless array

        sizes = array.elements.map do |size|
          next size.value if size.value > 0

          message = 'array size must be positive'
          raise_evaluation_error message, size.token_range
        end

        index_list =
          sizes
          .map { |size| size.times.to_a }
          .then { |list| list[0].product(*list[1..]) }
        id = array_id
        index_list.each.with_index(1) do |indices, i|
          info = ArrayInfo.new(id, indices, sizes, i == 1, i == index_list.size)
          yield(info)
        end
      end

      def array_id
        @array_id ||= - 1
        @array_id += 1
      end
    end

    module ArrayInstance
      attr_accessor :array_info

      def array?
        !array_info.nil?
      end

      def array_indices
        array_info&.indices
      end

      def array_sizes
        array_info&.sizes
      end

      def first_element?
        !array? || array_info.first
      end

      def last_element?
        !array? || array_info.last
      end
    end
  end
end
