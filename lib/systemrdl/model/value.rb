# frozen_string_literal: true

module SystemRDL
  module Model
    Value = Struct.new(:name, :value, :instance, :token_range) do
      def full_name(exclude_addrmap: false)
        [instance.full_name(exclude_addrmap:), name].reject(&:empty?).join('.')
      end

      def to_s
        value.to_s
      end

      def inspect
        to_s
      end

      def pretty_print(pp)
        pp.text("#{name}: ")
        pp_value(pp)
      end

      def value?
        true
      end

      def instance_ref?
        false
      end

      def property_ref?
        false
      end

      private

      def pp_value(pp)
        pp.pp(value)
      end
    end

    class ReferenceValue < Value
      def to_s
        full_name
      end

      def value?
        false
      end

      def instance_ref?
        value.is_a?(Instance)
      end

      def property_ref?
        value.is_a?(Value)
      end

      private

      def pp_value(pp)
        pp.text(value.full_name)
      end
    end

    class HexValue < Value
      def to_s
        "0x#{value.to_s(16)}"
      end

      private

      def pp_value(pp)
        pp.text(to_s)
      end
    end
  end
end
