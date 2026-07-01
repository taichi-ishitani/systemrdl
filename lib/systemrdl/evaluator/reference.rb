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
        result = base.instances.find do |inst|
          inst.name == id.value && match_array_indices?(inst)
        end
        return result if result

        # TODO
        # Report error
      end

      private

      def match_array_indices?(instance)
        # non array instance && array select
        # array instance && no array select
        return false if instance.array? != array?

        # non array instance
        return true unless instance.array?

        # check size
        return false if instance.array_indices.size != array.values.size

        instance
          .array_indices
          .zip(array.values)
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

      def find(base)
        @elements.inject(base) { |result, element| element.find(result) }
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

      def find(base)
        inst = @instance_ref&.find(base) || base
        result = inst.property(@prop.value)
        return result if result

        # TODO
        # Report error
      end
    end
  end
end
