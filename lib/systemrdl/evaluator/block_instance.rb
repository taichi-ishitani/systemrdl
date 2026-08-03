# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module BlockInstance
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
