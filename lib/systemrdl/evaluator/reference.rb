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
        return result unless result.empty?

        inst_name =
          if array_select?
            array
              .elements
              .inject([id.value]) { |elements, select| elements << "[#{select.value}]" }
              .join
          else
            id.value.to_s
          end
        raise_evaluation_error "unresolvable instance: #{inst_name}", token_range
      end

      def array_select?
        !array.nil?
      end

      private

      def find_instance(base)
        base.instances.select do |inst|
          inst.name == id.value && match_array_indices?(inst)
        end
      end

      def match_array_indices?(instance)
        # non array instance && array select
        return false if !instance.array? && array_select?

        # non array instance or whole array
        return true unless array_select?

        # check size
        return false if instance.array_indices.size != array.size

        instance
          .array_indices
          .zip(array.elements)
          .all? { |index, select| index == select.value }
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
        find(instance, allow_array_ref: false)[0].to_value(token_range)
      end

      def find(instance, allow_array_ref: false)
        result = @elements.inject([instance]) do |instances, element|
          process_instance_ref_element(instances, element)
        end

        return result if allow_array_ref || result.size <= 1

        message = 'reference to array instance not allowed'
        raise_evaluation_error message, token_range
      end

      def array_select?
        elements.any?(&:array_select?)
      end

      private

      def process_instance_ref_element(instances, element)
        instances.flat_map { |inst| element.find(inst) }
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

      def evaluate(instance, **_optargs)
        find(instance, allow_array_ref: false)[0].to_value(token_range)
      end

      def find(instance, allow_array_ref: false)
        insts =
          if @instance_ref
            @instance_ref.find(instance, allow_array_ref:)
          else
            [instance]
          end

        insts.map do |inst|
          prop = inst.property(@prop.value)
          next prop if prop

          raise_evaluation_error "undefined property: #{@prop.value}", token_range
        end
      end

      def array_select?
        @instance_ref&.array_select? || false
      end
    end
  end
end
