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

        # TODO
        # check duplicated param def element
      end

      def evaluate(instance, param_inst, **optargs)
        # TODO
        # check param arity

        @elements&.each do |def_element|
          instance.params << def_element.evaluate(instance, param_inst, **optargs)
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

      def evaluate(instance, param_inst, **optargs)
        value = eval_param_value(instance, param_inst, **optargs)
        value =
          if @type.value == :longint
            # `longint` type is treated as `bit` type internally
            value.coerce([:bit])
          else
            value.coerce([@type.value])
          end
        ParameterValue.new(@id.value, value)
      end

      private

      def eval_param_value(instance, param_inst, **optargs)
        if (inst_value = param_inst&.dig(@id.value))
          inst_value
        elsif @default_value
          @default_value.evaluate(instance, **optargs)
        else
          # TODO
          # report error
        end
      end
    end

    class ParameterInst
      include Common

      def initialize(elements, token_range)
        super(token_range)
        @elements = elements

        # TODO
        # check duplicated param element
      end

      def evaluate(instance, **optargs)
        @elements&.to_h do |element|
          value = element.value.evaluate(instance, **optargs)
          [element.id.value, value]
        end
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
