# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:root) do
        descriptions = [
          component_definition, explicit_component_inst, property_assignment
        ]
        spaces? >> descriptions.inject(:|) >> spaces?
      end
    end
  end
end
