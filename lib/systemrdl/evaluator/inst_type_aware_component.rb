# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module InstTypeAwareComponent
      private

      def apply_inst_type(instance, inst_type)
        instance.inst_type = inst_type || :internal
      end
    end

    module InstTypeAwareInstance
      attr_writer :inst_type

      def external?
        @inst_type == :external
      end
    end
  end
end
