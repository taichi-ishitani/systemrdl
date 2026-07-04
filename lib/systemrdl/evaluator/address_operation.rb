# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module AddressOperation
      private

      def apply_explicit_address(instance, inst_values)
        address = inst_values[:address_assignment]&.to_value
        return unless address

        instance.address = address
      end

      def apply_stride(instance, inst_values)
        stride = inst_values[:address_stride]&.to_value
        return unless stride

        instance.stride = stride
      end

      def apply_alignment(instance, inst_values)
        alignment = inst_values[:address_alignment]&.to_value
        return unless alignment

        instance.alignment = alignment
      end

      def apply_address_operations(instance, inst_values)
        apply_explicit_address(instance, inst_values)
        apply_stride(instance, inst_values)
        apply_alignment(instance, inst_values)

        return unless instance.address && instance.alignment

        message = '@ and %= address operations are mutually exclusive'
        raise_evaluation_error message, instance.address.token_range, instance.alignment.token_range
      end

      def check_accesswidth_boundary(instance, label, value)
        return unless value

        accesswidth = instance.accesswidth
        return if (value.value % (accesswidth / 8)) == 0

        message =
          "#{label} not aligned to accesswidth: " \
          "#{label} 0x#{value.value.to_s(16)} accesswidth #{accesswidth}"
        raise_evaluation_error message, value.token_range
      end

      def check_address(instance)
        check_accesswidth_boundary(instance, :address, instance.address)
      end

      def check_stride(instance)
        stride = instance.stride
        return unless stride

        check_accesswidth_boundary(instance, :stride, stride)

        size = instance.size
        return if stride.value >= size

        message =
          "stride less than #{instance.layer} size: " \
          "stride 0x#{stride.value.to_s(16)} #{instance.layer} size #{size}"
        raise_evaluation_error message, stride.token_range
      end

      def check_alignment(instance)
        alignment = instance.alignment
        return unless alignment

        check_accesswidth_boundary(instance, :alignment, alignment)

        return if alignment.value > 0

        message = 'alignment must be positive'
        raise_evaluation_error message, alignment.token_range
      end

      def check_address_operations(instance)
        check_address(instance)
        check_stride(instance)
        check_alignment(instance)
      end
    end
  end
end
