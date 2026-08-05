# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module BlockComponent
      include ArrayComponent
      include AddressOperation
      include ContainerComponent
      include AddressAllocation

      private

      def check_alignment_property(instance)
        check_power_of_2(instance, :alignment, 1)
      end
    end

    module BlockInstance
      include ArrayInstance

      attr_accessor :address
      attr_accessor :stride
      attr_accessor :alignment

      def accesswidth
        @accesswidth ||= instances.map(&:accesswidth).max
      end

      def size
        @size ||= instances.map { |inst| inst.address.value + inst.size }.max
      end

      def sw_readable?
        true
      end

      def sw_writable?
        true
      end
    end
  end
end
