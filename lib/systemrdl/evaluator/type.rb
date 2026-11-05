# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module Type
      class Base
        def to_s
          kind.to_s
        end

        def width
        end

        def cast(value, target, _token_range)
          (equal?(target) && value) || nil
        end
      end

      class Bit < Base
        def initialize(width)
          super()
          @width = width
        end

        attr_reader :width

        def kind
          :bit
        end

        def cast(value, target, token_range)
          token_range ||= value.token_range
          if target.kind == :boolean
            Value.new(value.value != 0, target, token_range)
          elsif target.kind == :bit && target.width
            mask = (1 << target.width) - 1
            Value.new(value.value & mask, target, token_range)
          elsif target.kind == :bit
            Value.new(value.value, value.type, token_range)
          else
            super
          end
        end
      end

      class Boolean < Base
        def kind
          :boolean
        end

        def width
          1
        end

        def cast(value, target, token_range)
          if target.kind == :bit
            type = (target.width && target) || Type.bit(width)
            Value.new((value.value && 1) || 0, type, token_range)
          else
            super
          end
        end
      end

      class String < Base
        def kind
          :string
        end
      end

      class BuiltinEnum < Base
        def initialize(kind)
          super()
          @kind = kind
        end

        attr_reader :kind
      end

      class InstRef < Base
        def initialize(layer)
          super()
          @kind = :"#{layer}_ref"
        end

        attr_reader :kind
      end

      class PropRef < Base
        def kind
          :prop_ref
        end
      end

      class EnumRef < Base
        def kind
          :enum_ref
        end
      end

      def self.bit(width = nil)
        @bit_types ||= Hash.new do |h, k|
          h[k] = Bit.new(k)
        end
        @bit_types[width]
      end

      def self.unsized_bit
        bit(nil)
      end

      def self.longint
        bit(64)
      end

      def self.boolean
        @boolean_type ||= Boolean.new
      end

      def self.string
        @string_type ||= String.new
      end

      def self.builtin_enum(kind)
        @builtin_enum_types ||= Hash.new do |h, k|
          h[k] = BuiltinEnum.new(k)
        end
        @builtin_enum_types[kind]
      end

      [:accesstype, :addressingtype, :onreadtype, :onwritetype, :precedencetype].each do |enum|
        instance_eval(<<~METHOD, __FILE__, __LINE__ + 1)
          # def self.accesstype
          #   builtin_enum(__method__)
          # end
          def self.#{enum}
            builtin_enum(__method__)
          end
        METHOD
      end

      def self.inst_ref(layer)
        @inst_ref_types ||= Hash.new do |h, k|
          h[k] = InstRef.new(k)
        end
        @inst_ref_types[layer]
      end

      [:addrmap, :regfile, :reg, :field, :mem].each do |layer|
        instance_eval(<<~METHOD, __FILE__, __LINE__ + 1)
          # def self.addrmap_ref
          #   inst_ref(:addrmap)
          # end
          def self.#{layer}_ref
            inst_ref(:#{layer})
          end
        METHOD
      end

      def self.prop_ref
        @prop_ref_type ||= PropRef.new
      end

      def self.enum_ref
        @enum_ref_type ||= EnumRef.new
      end

      def self.get(type, *args)
        __send__(type, *args)
      end
    end
  end
end
