# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module AddressAllocation
      private

      def apply_explicit_address(instance, inst_values)
        address = inst_values[:address_assignment]&.to_value
        return unless address

        instance.address = address
      end

      def check_accesswidth_boundary(instance, value)
        return unless value

        accesswidth = inst_accesswidth(instance)
        return if (value.value % (accesswidth / 8)) == 0

        message = yield(value.value, accesswidth)
        raise_evaluation_error message, value.token_range
      end

      def check_address(instance)
        check_accesswidth_boundary(instance, instance.address) do |address, accesswidth|
          "address not aligned to accesswidth: address 0x#{address.to_s(16)} accesswidth #{accesswidth}"
        end
      end
    end
  end
end
