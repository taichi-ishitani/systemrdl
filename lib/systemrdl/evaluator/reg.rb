# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class RegDefinition < ComponentDefinition
      private

      def instnace_class
        RegInstance
      end

      def init_properties(instance)
        super

        #
        # Table 23—Register properties
        #
        create_property(instance, :regwidth, [:longint], nil)
        create_property(instance, :accesswidth, [:longint], nil)
        create_property(instance, :errextbus, [:boolean], false)
        create_property(instance, :shared, [:boolean], false)
      end
    end

    class RegInstance < Instance
    end
  end
end
