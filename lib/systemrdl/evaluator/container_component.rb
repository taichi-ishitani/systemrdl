# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module ContainerComponent
      private

      def check_structural_component_instances(instance)
        return if instance.instances.any?(&:structural_component?)

        message = "no structural component instances within #{layer}"
        raise_evaluation_error message, instance.token_range
      end
    end
  end
end
