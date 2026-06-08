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
        result = base.instances.find { |inst| inst.name == id.value }
        return result if result

        # TODO
        # Report error
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
