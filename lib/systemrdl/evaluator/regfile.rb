# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegFileDefinition < ComponentDefinition
      def layer
        :regfile
      end

      private

      def instance_class
        RegFileInstance
      end

      def init_properties(instance)
        super

        #
        # Table 25—Register file properties
        #
        create_property(instance, :alignment, [:longint], nil)
        create_property(instance, :sharedextbus, [:boolean], false)
        create_property(instance, :errextbus, [:boolean], false)
      end
    end

    class RegFileInstance < Instance
      def layer
        :regfile
      end

      def definable?(definition)
        definition.layer in :regfile | :reg
      end
    end
  end
end
