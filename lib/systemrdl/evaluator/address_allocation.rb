# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module AddressAllocation
      private

      def allocate_addresses(instance)
        address = 0
        instance.instances.each do |child_inst|
          # For now, support reg only
          next unless child_inst.reg?

          assign_address(address, instance, child_inst)
          address = calc_next_address(child_inst)
        end
      end

      def assign_address(current_address, inst, child_inst)
        if child_inst.first_element?
          child_inst.address ||= begin
            alignment = calc_alignment(inst, child_inst)
            address = roundup(current_address, alignment)
            Value.new(address, nil)
          end
        else
          # Array non-head elements carry a copy of the head's @ address at this point;
          # overwrite with the stride-accumulated address for this element.
          child_inst.address = Value.new(current_address, nil)
        end
      end

      def calc_alignment(inst, child_inst)
        inst_alignment = child_inst.alignment&.value
        return inst_alignment if inst_alignment

        alignments = [
          inst.property_value(:alignment)&.value || 0,
          child_inst.accesswidth / 8,
          alignment_by_addressing(inst, child_inst)
        ]
        alignments.max
      end

      def alignment_by_addressing(inst, child_inst)
        addressing = inst.property_value(:addressing).value
        case addressing
        when :compact then child_inst.accesswidth / 8
        when :regalign then aligned_size(child_inst)
        when :fullalign then calc_fullalign_alignment(child_inst)
        end
      end

      def calc_fullalign_alignment(child_inst)
        return aligned_size(child_inst) unless child_inst.array?

        n_elements = child_inst.array_info.n_elements
        array_size = ((n_elements - 1) * aligned_size(child_inst)) + child_inst.size

        if power_of_2?(array_size, 1)
          array_size
        else
          2**array_size.bit_length
        end
      end

      def calc_next_address(child_inst)
        delta =
          if child_inst.last_element?
            child_inst.size
          elsif child_inst.stride
            child_inst.stride.value
          else
            aligned_size(child_inst)
          end
        child_inst.address.value + delta
      end

      def roundup(dividend, divisor)
        divisor * dividend.ceildiv(divisor)
      end

      def aligned_size(child_inst)
        roundup(child_inst.size, child_inst.accesswidth / 8)
      end
    end
  end
end
