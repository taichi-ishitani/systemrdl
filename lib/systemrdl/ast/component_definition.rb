# frozen_string_literal: true

module SystemRDL
  module AST
    class ComponentInstances < Base
      def initialize(id, inst_type, alias_id, parameter_assignments, insts)
        assign_properties(
          id: id, inst_type: to_symbol(inst_type), alias_id: alias_id,
          parameter_assignments: to_array(parameter_assignments), insts: to_array(insts)
        )
        super(:component_instances, id, inst_type, insts)
      end

      attr_reader :id
      attr_reader :inst_type
      attr_reader :alias_id
      attr_reader :parameter_assignments
      attr_reader :insts
    end

    class ParameterAssignment < Base
      def initialize(id, value)
        assign_properties(id: id, value: value)
        super(:parameter_assignment, id)
      end

      attr_reader :id
      attr_reader :value
    end

    class ComponentInstance < Base
      def initialize(id, array, range, assignments)
        assign_properties(
          id: id, array: array, range: range,
          assignments: extract_assignments(assignments)
        )
        super(:component_instance, id)
      end

      attr_reader :id
      attr_reader :array
      attr_reader :range
      attr_reader :assignments

      private

      def extract_assignments(assignments)
        return nil if assignments.empty?

        assignments.values
      end
    end

    class InstanceAssignment < Base
      def initialize(operator, operand)
        assign_properties(operator: operator.to_sym, operand: operand)
        super(:instnace_assignment, operator)
      end

      attr_reader :operator
      attr_reader :operand
    end

    class ParameterDefinition < Base
      def initialize(id, data_type, default)
        assign_properties(id: id, data_type: data_type, default: default)
        super(:paraemter_definition, data_type)
      end

      attr_reader :id
      attr_reader :data_type
      attr_reader :default
    end

    class ComponentDefinition < Base
      def initialize(component_type, id, parameter_definitions, body, insts)
        assign_properties(
          id: id, parameter_definitions: to_array(parameter_definitions),
          body: to_array(body), insts: insts
        )
        super(:"#{component_type}_definition", component_type)
      end

      attr_reader :id
      attr_reader :parameter_definitions
      attr_reader :body
      attr_reader :insts
    end

    class FieldDefinition < ComponentDefinition
    end

    class RegisterDefinition < ComponentDefinition
    end

    class MemoryDefinition < ComponentDefinition
    end

    class RegisterFileDefinition < ComponentDefinition
    end

    class AddressMapDefinition < ComponentDefinition
    end
  end
end
