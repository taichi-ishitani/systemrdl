# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class InstanceRefElement
      include Common

      def initialize(id, array, token_range)
        super(token_range)
        @id = id
        @array = array
      end

      attr_reader :id
      attr_reader :array

      def find(base)
        result = find_instance(base)
        return result if result

        inst_name =
          if array?
            array
              .elements
              .inject([id.value]) { |elements, select| elements << "[#{select.value}]" }
              .join
          else
            id.value.to_s
          end
        raise_evaluation_error "unresolvable instance: #{inst_name}", token_range
      end

      private

      def find_instance(base)
        base.instances.find do |inst|
          inst.name == id.value && match_array_indices?(inst)
        end
      end

      def match_array_indices?(instance)
        # non array instance && array select
        # array instance && no array select
        return false if instance.array? != array?

        # non array instance
        return true unless instance.array?

        # check size
        return false if instance.array_indices.size != array.size

        instance
          .array_indices
          .zip(array.elements)
          .all? { |index, select| index == select.value }
      end

      def array?
        !array.nil?
      end
    end

    class InstanceRef
      include Common

      def initialize(elements, token_range)
        super(token_range)
        @elements = elements
      end

      attr_reader :elements

      def evaluate(instance, **_optargs)
        find(instance).to_value(token_range)
      end

      def find(instance)
        @elements
          .inject(instance) { |result, element| element.find(result) }
      end
    end

    class PropRef
      include Common

      def initialize(instance_ref, prop, token_range)
        super(token_range)
        @instance_ref = instance_ref
        @prop = prop
      end

      attr_reader :instance_ref
      attr_reader :prop

      def evaluate(instance, **optargs)
        find(instance, **optargs).to_value(token_range)
      end

      def find(instance, **optargs)
        inst = @instance_ref&.find(instance, **optargs) || instance
        result = inst.property(@prop.value)
        return result if result

        raise_evaluation_error "undefined property: #{@prop.value}", token_range
      end
    end
  end
end
