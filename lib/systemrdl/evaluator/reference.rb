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

      def find(base, instance_only:)
        result = find_instance(base)
        return result if result

        result = find_property(base) unless instance_only
        return result if result

        # TODO
        # Report error
      end

      private

      def find_instance(base)
        base.instances.find do |inst|
          inst.name == id.value && match_array_indices?(inst)
        end
      end

      def find_property(base)
        base.property(id.value)
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
        instance_only = @elements.size > 1
        @elements
          .inject(instance) { |result, element| element.find(result, instance_only:) }
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

        # TODO
        # Report error
      end
    end
  end
end
