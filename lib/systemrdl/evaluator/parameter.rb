# frozen_string_literal: true

module SystemRDL
  module Evaluator
    ParameterValue = Data.define(:name, :value) do
      def to_value(_token_range)
        value
      end

      def expression_width(_instance)
        value.width
      end

      def array?
        false
      end
    end

    class ParameterDef
      include Common

      def initialize(elements, token_range)
        super(token_range)
        @elements = elements

        check_duplication
      end

      def evaluate(instance, param_inst, **optargs)
        check_param_inst(param_inst)
        @elements&.each do |def_element|
          instance.params << def_element.evaluate(instance, param_inst, **optargs)
        end
      end

      private

      def check_duplication
        @elements&.each do |element|
          elements = select_elements_by_id(element.id)
          next if elements.size == 1

          message = "duplicated parameter: #{element.id}"
          raise_evaluation_error message, elements[1].token_range
        end
      end

      def select_elements_by_id(id)
        @elements.select { |element| element.id.value == id.value }
      end

      def check_param_inst(param_inst)
        param_inst&.each do |id, (_, token_range)|
          next if @elements&.any? { |element| element.id.value == id }

          message = "unknown parameter: #{id}"
          raise_evaluation_error message, token_range
        end
      end
    end

    class ParameterDefElement
      include Common

      def initialize(id, type, default_value, token_range)
        super(token_range)
        @id = id
        @type = type
        @default_value = default_value
      end

      attr_reader :id

      def evaluate(instance, param_inst, **optargs)
        value, token_range = eval_param_value(instance, param_inst, **optargs)
        value = value.coerce([value_type]) do |expected, actual|
          message =
            "type mismatch for #{@id} parameter: " \
            "expected #{expected[0]} actual #{actual}"
          raise_evaluation_error message, token_range
        end
        ParameterValue.new(@id.value, value)
      end

      private

      def eval_param_value(instance, param_inst, **optargs)
        if (value = param_inst&.dig(@id.value))
          value
        elsif @default_value
          [@default_value.evaluate(instance, **optargs), token_range]
        else
          message = "missing mandatory parameter: #{@id}"
          raise_evaluation_error message, token_range
        end
      end

      def value_type
        if @type.value == :longint
          # `longint` type is treated as `bit` type internally
          :bit
        else
          @type.value
        end
      end
    end

    class ParameterInst
      include Common

      def initialize(elements, token_range)
        super(token_range)
        @elements = elements

        check_duplication
      end

      def evaluate(instance, **optargs)
        @elements&.to_h do |element|
          value = element.value.evaluate(instance, **optargs)
          [element.id.value, [value, token_range]]
        end
      end

      private

      def check_duplication
        @elements&.each do |element|
          elements = select_elements_by_id(element.id)
          next if elements.size == 1

          message = "duplicated parameter override: #{element.id}"
          raise_evaluation_error message, elements[1].token_range
        end
      end

      def select_elements_by_id(id)
        @elements.select { |element| element.id.value == id.value }
      end
    end

    class ParameterElement
      include Common

      def initialize(id, value, token_range)
        super(token_range)
        @id = id
        @value = value
      end

      attr_reader :id
      attr_reader :value
    end
  end
end
