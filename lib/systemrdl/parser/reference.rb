# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:instance_ref_element) do
        (
          (id.as(:id) >> spaces? >> array.as(:array)) | id.as(:id)
        ).as(:instance_ref_element) >> spaces?
      end

      rule(:instance_ref) do
        (
          instance_ref_element >>
          (spaced('.') >> instance_ref_element).repeat
        ).as(:instance_ref)
      end

      rule(:property_ref) do
        define_property_ref(id)
      end

      private

      def define_property_ref(property_atom)
        (
          instance_ref >> spaced('->') >> property_atom.as(:property)
        ).as(:property_ref) >> spaces?
      end
    end

    define_transformer do
      rule(instance_ref_element: { id: simple(:id) }) do
        AST::ReferenceElement.new(id, [])
      end

      rule(instance_ref_element: { id: simple(:id), array: sequence(:array) }) do
        AST::ReferenceElement.new(id, array)
      end

      rule(instance_ref: simple(:inst)) do
        AST::Reference.new([inst], nil)
      end

      rule(instance_ref: sequence(:inst)) do
        AST::Reference.new(inst, nil)
      end

      rule(property_ref: { instance_ref: simple(:inst), property: simple(:prop) }) do
        AST::Reference.new([inst], prop)
      end

      rule(property_ref: { instance_ref: sequence(:inst), property: simple(:prop) }) do
        AST::Reference.new(inst, prop)
      end
    end
  end
end
