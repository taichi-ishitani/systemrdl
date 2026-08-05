# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module InstTypeAwareComponent
      private

      def apply_inst_type(instance, inst_type)
        instance.external = inst_type == :external
      end
    end

    module InstTypeAwareInstance
      attr_accessor :external
    end
  end
end
