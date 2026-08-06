# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module AddressAllocation
      private

      def allocate_addresses(instance)
        address = 0
        instance.instances.each do |child_inst|
          next unless addressable_inst?(child_inst)

          assign_address(address, instance, child_inst)
          address = calc_next_address(child_inst)
        end
      end

      def assign_address(current_address, inst, child_inst)
        if child_inst.first_element?
          child_inst.address ||= begin
            alignment = calc_alignment(inst, child_inst)
            address = roundup(current_address, alignment)
            Value.new(address, :bit, 64, nil)
          end
        else
          # Array non-head elements carry a copy of the head's @ address at this point;
          # overwrite with the stride-accumulated address for this element.
          child_inst.address = Value.new(current_address, :bit, 64, nil)
        end
      end

      def calc_alignment(inst, child_inst)
        inst_alignment = child_inst.alignment&.value
        return inst_alignment if inst_alignment

        alignments = [
          inst_alignment(inst),
          child_inst.accesswidth / 8,
          alignment_by_addressing(inst, child_inst)
        ]
        alignments.max
      end

      def inst_alignment(inst)
        alignment =
          if inst.mem?
            inst.parent.property_value(:alignment)
          else
            inst.property_value(:alignment)
          end
        alignment&.value || 0
      end

      def alignment_by_addressing(inst, child_inst)
        addressing = effective_addressing(inst)
        case addressing
        when :compact then child_inst.accesswidth / 8
        when :regalign then aligned_size(child_inst)
        when :fullalign then calc_fullalign_alignment(child_inst)
        end
      end

      def effective_addressing(inst)
        addrmap =
          if RUBY_VERSION >= '4.0'
            inst.upper_instances(include_root: false, include_self: true).rfind(&:addrmap?)
          else
            inst.upper_instances(include_root: false, include_self: true).reverse_each.find(&:addrmap?)
          end
        addrmap.property_value(:addressing).value
      end

      def calc_fullalign_alignment(child_inst)
        return aligned_size(child_inst) unless child_inst.array?

        array_size = calc_occupied_size(child_inst)
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
          else
            element_stride(child_inst)
          end
        child_inst.address.value + delta
      end

      def check_overlapping_address_ranges(instance)
        insts = instance.instances.select { |inst| addressable_inst?(inst) && inst.first_element? }
        insts.combination(2).each do |(inst_a, inst_b)|
          next unless overlapping_pair?(inst_a, inst_b)

          message = 'overlapping address ranges not allowed'
          raise_evaluation_error message, inst_a.token_range, inst_b.token_range
        end
      end

      def overlapping_pair?(inst_a, inst_b)
        range_a = calc_address_range(inst_a)
        range_b = calc_address_range(inst_b)
        return false unless range_a.include?(range_b.begin) || range_b.include?(range_a.begin)

        r_a = inst_a.sw_readable?
        w_a = inst_a.sw_writable?
        r_b = inst_b.sw_readable?
        w_b = inst_b.sw_writable?
        (r_a && r_b) || (w_a && w_b)
      end

      def calc_address_range(child_inst)
        base = child_inst.address.value
        size = calc_occupied_size(child_inst)
        base...(base + size)
      end

      def roundup(dividend, divisor)
        divisor * dividend.ceildiv(divisor)
      end

      def aligned_size(child_inst)
        roundup(child_inst.size, child_inst.accesswidth / 8)
      end

      def calc_occupied_size(child_inst)
        if child_inst.array?
          n_elements = child_inst.array_info.n_elements
          ((n_elements - 1) * element_stride(child_inst)) + child_inst.size
        else
          child_inst.size
        end
      end

      def element_stride(child_inst)
        child_inst.stride&.value || aligned_size(child_inst)
      end

      def addressable_inst?(inst)
        inst.addrmap? || inst.regfile? || inst.mem? || inst.reg?
      end
    end
  end
end
