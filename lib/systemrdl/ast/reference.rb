# frozen_string_literal: true

module SystemRDL
  module AST
    class ReferenceElement < Base
      def initialize(id, array)
        assign_properties(id: id, array: array)
        super(:reference_element, id)
      end

      attr_reader :id
      attr_reader :array
    end

    class Reference < Base
      def initialize(instance_refernce, property)
        assign_properties(instance_refernce: instance_refernce, property: property)
        super(:reference, instance_refernce, property)
      end

      attr_reader :instance_refernce
      attr_reader :property
    end
  end
end
