# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class MemDefinition < ComponentDefinition
      include InstTypeAwareComponent
      include BlockComponent

      def validate(instance)
        check_positive_value(instance, :mementries)
        check_memwidth(instance)
        check_regwidth(instance)
        check_virtual_field_pos(instance)
        check_virtual_field_sw(instance)
      end

      def revalidate(instance)
        check_virtual_field_sw(instance)
      end

      def finalize(instance)
        allocate_addresses(instance)
        check_address_operations(instance)
        check_reg_size(instance)
      end

      def layer
        :mem
      end

      def support_inst_type?(inst_type)
        inst_type == :external
      end

      private

      def instance_class
        MemInstance
      end

      def apply_inst_values(instance, inst_values)
        apply_address_operations(instance, inst_values)
        check_range(inst_values)
      end

      def post_build(instance)
        apply_default_memwidth(instance)
      end

      def apply_default_memwidth(instance)
        return if no_regs?(instance)

        property = instance.property(:memwidth)
        return if property.value

        entrywidth = Value.new(instance.entrywidth, :bit, 64, nil)
        property.assign(entrywidth)
      end

      def check_memwidth(instance)
        check_positive_value(instance, :memwidth)

        memwidth = instance.property_value(:memwidth)
        return if memwidth || !no_regs?(instance)

        message = 'omitting memwidth without virtual regs not allowed'
        raise_evaluation_error message, instance.token_range
      end

      def check_positive_value(instance, prop_name)
        value = instance.property_value(prop_name)
        return if value.nil? || value.value >= 1

        message = "#{prop_name} must be positive"
        raise_evaluation_error message, value.token_range
      end

      def check_regwidth(instance)
        return if no_regs?(instance)

        entrywidth = instance.entrywidth
        instance.instances.each do |reg|
          regwidth = reg.property_value(:regwidth).value
          next if regwidth <= entrywidth

          memwidth = instance.property_value(:memwidth)
          message =
            'regwidth larger than entry width not allowed: ' \
            "entry width #{entrywidth} (memwidth #{memwidth}) regwidth #{regwidth}"
          raise_evaluation_error message, reg.token_range
        end
      end

      def check_virtual_field_pos(instance)
        return if no_regs?(instance)

        memwidth = instance.property_value(:memwidth).value
        instance.instances.flat_map(&:instances).each do |field|
          next if field.msb.value < memwidth

          message =
            'virtual field outside memwidth not allowed: ' \
            "memwidth #{memwidth} msb #{field.msb} lsb #{field.lsb}"
          raise_evaluation_error message, field.token_range
        end
      end

      def check_virtual_field_sw(instance)
        return if no_regs?(instance)

        mem_sw = instance.property_value(:sw).value
        instance.instances.flat_map(&:instances).each do |field|
          field_sw = field.property_value(:sw).value
          next if field_sw == mem_sw

          message =
            'mismatch between mem sw and virtual field sw: ' \
            "mem #{mem_sw} virtual field #{field_sw}"
          raise_evaluation_error message, field.token_range
        end
      end

      def check_reg_size(instance)
        return if no_regs?(instance)

        size = instance.size
        instance.instances.each do |reg|
          reg_addr = reg.address.value
          reg_size = reg.size
          next if (reg_addr + reg_size) <= size

          message =
            'virtual reg outside mem area not allowed: ' \
            "mem size #{size} reg address 0x#{reg_addr.to_s(16)} reg size #{reg_size}"
          raise_evaluation_error message, reg.token_range
        end
      end

      def no_regs?(instance)
        instance.instances.empty?
      end
    end

    class MemInstance < Instance
      include InstTypeAwareInstance
      include BlockInstance

      def entrywidth
        @entrywidth ||=
          if (memwidth = property_value(:memwidth)&.value)
            if memwidth <= 8
              8
            elsif memwidth.nobits?(memwidth - 1)
              memwidth
            else
              2**memwidth.bit_length
            end
          else
            instances
              .map { |inst| inst.property_value(:regwidth).value }
              .max
          end
      end

      def accesswidth
        (instances.empty? && entrywidth) || super
      end

      def size
        @size ||= begin
          width = entrywidth / 8
          entries = property_value(:mementries).value
          width * entries
        end
      end

      def definable?(definition)
        definition.layer in :reg | :field
      end

      def instantiable?(definition)
        definition.layer in :reg
      end
    end
  end
end
