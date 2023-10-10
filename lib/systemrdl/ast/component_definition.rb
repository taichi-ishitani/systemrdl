# frozen_string_literal: true

module SystemRDL
  module AST
    class ComponentInstances < Base
      def initialize(position, id, inst_type, alias_id, insts)
        assign_properties(
          id: id, inst_type: inst_type, alias_id: alias_id, insts: insts
        )
        super(:component_instances, position)
      end

      attr_reader :id
      attr_reader :inst_type
      attr_reader :alias_id
      attr_reader :insts
    end

    class ComponentInstance < Base
      def initialize(position, id, array, range, assignment)
        assign_properties(
          id: id, array: array, range: range, assignment: assignment
        )
        super(:component_instance, position)
      end

      attr_reader :id
      attr_reader :array
      attr_reader :range
      attr_reader :assignment
    end

    class InstanceAssignment < Base
      def initialize(position, operator, operand)
        assign_properties(operator: operator, operand: operand)
        super(:instnace_assignment, position)
      end

      attr_reader :operator
      attr_reader :operand
    end

    class ComponentDefinition < Base
      def initialize(type, position, id, body, insts)
        assign_properties(id: id, body: body, insts: insts)
        super(type, position)
      end

      attr_reader :id
      attr_reader :body
      attr_reader :insts
    end

    class FieldDefinition < ComponentDefinition
      def initialize(position, id, body, insts)
        super(:field_definition, position, id, body, insts)
      end
    end

    class RegisterDefinition < ComponentDefinition
      def initialize(position, id, body, insts)
        super(:register_definition, position, id, body, insts)
      end
    end

    class MemoryDefinition < ComponentDefinition
      def initialize(position, id, body, insts)
        super(:memory_definition, position, id, body, insts)
      end
    end
  end
end
