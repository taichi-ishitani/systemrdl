# frozen_string_literal: true

module SystemRDL
  module AST
    class ReferenceElement < Base
      def initialize(position, id)
        assign_properties(id: id)
        super(:reference_element, position)
      end

      attr_reader :id
    end

    class Reference < Base
      def initialize(position, instance_refernce, property)
        assign_properties(instance_refernce: instance_refernce, property: property)
        super(:reference, position)
      end

      attr_reader :instance_refernce
      attr_reader :property
    end
  end
end
