# frozen_string_literal: true

module SystemRDL
  module Model
    Value = Data.define(:name, :value, :instance, :token_range) do
      def full_name
        "#{instance.full_name}.#{name}"
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

      private

      def pp_value(pp)
        pp.pp(value)
      end
    end

    class ReferenceValue < Value
      def to_s
        full_name
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
