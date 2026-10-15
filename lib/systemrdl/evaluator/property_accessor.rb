# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module PropertyAccessor
      def properties
        @properties ||= []
      end

      def property(name)
        properties.find { |prop| prop.name == name }
      end

      def property_value(name)
        property(name)&.value
      end
    end
  end
end
