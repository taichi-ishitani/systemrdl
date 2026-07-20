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
