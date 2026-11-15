# frozen_string_literal: true

module SystemRDL
  module Model
    class Instance
      include Common

      def initialize(inst, parent, model_map)
        super(inst, inst.element_name, parent, inst.token_range, model_map)
        @layer = inst.layer
        @types = build_types(inst, model_map).freeze
        @instances = build_sub_instances(inst, model_map).freeze
        @properties = build_properties(inst, model_map).freeze
        @signature = Signature.generate(inst)
        freeze
      end

      attr_reader :layer
      attr_reader :types
      attr_reader :instances
      attr_reader :signature

      def to_s
        "#{name} (#{layer})"
      end

      def full_name(exclude_addrmap: false)
        hierarchy(exclude_root: true, exclude_addrmap:).map(&:name).join('.')
      end

      def hierarchy(exclude_root: false, exclude_addrmap: false)
        if (layer == :root && exclude_root) || (layer == :addrmap && exclude_addrmap)
          []
        elsif layer == :root
          [self]
        else
          instances = parent.hierarchy(exclude_root:, exclude_addrmap:)
          instances << self
          instances
        end
      end

      def pretty_print(pp)
        pp.group(2, "#{self} {", '}') do
          pp_types(pp)
          pp_properties(pp)
          pp_instances(pp)
        end
      end

      private

      def build_types(inst, model_map)
        inst.types.map { |type| Enum.new(type, self, model_map) }
      end

      def build_sub_instances(inst, model_map)
        inst.instances.map do |sub_inst|
          case sub_inst.layer
          when :addrmap then AddrMap.new(sub_inst, self, model_map)
          when :mem then Mem.new(sub_inst, self, model_map)
          when :regfile then RegFile.new(sub_inst, self, model_map)
          when :reg then Reg.new(sub_inst, self, model_map)
          when :field then Field.new(sub_inst, self, model_map)
          end
        end
      end

      def pp_types(pp)
        @types.each do |type|
          pp.breakable
          pp.pp(type)
        end
      end

      def pp_instances(pp)
        @instances.each do |inst|
          pp.breakable
          pp.pp(inst)
        end
      end
    end

    class Root < Instance
      alias_method :addrmaps, :instances
    end

    class AddrMap < Instance
      def_property :display_name
      def_property :desc
      def_property :address, HexValue
      def_property :size, &:size
      def_property :accesswidth, &:accesswidth
      def_property :sharedextbus
      def_property :errextbus
      def_property :bigendian
      def_property :littleendian
      def_property :rsvdset
      def_property :rsvdsetX
      def_property :msb0

      alias_method :regs, :instances
    end

    class Mem < Instance
      def_property :display_name
      def_property :desc
      def_property :address, HexValue
      def_property :size, &:size
      def_property :accesswidth, &:accesswidth
      def_property :entrywidth, &:entrywidth
      def_property :memwidth
      def_property :mementries
      def_property :sw

      alias_method :regs, :instances
    end

    class RegFile < Instance
      def_property :display_name
      def_property :desc
      def_property :external, &:external
      def_property :address, HexValue
      def_property :size, &:size
      def_property :accesswidth, &:accesswidth
      def_property :sharedextbus
      def_property :errextbus

      alias_method :regs, :instances
    end

    class Reg < Instance
      def_property :display_name
      def_property :desc
      def_property :external, &:external
      def_property :address, HexValue
      def_property :size, &:size
      def_property :accesswidth
      def_property :errextbus
      def_property :shared

      alias_method :fields, :instances
    end

    class Field < Instance
      def_property :display_name
      def_property :desc
      def_property :msb
      def_property :lsb
      def_property :width do |inst|
        msb = inst.msb.value
        lsb = inst.lsb.value
        msb - lsb + 1
      end
      def_property :hw
      def_property :sw
      def_property :next
      def_property :reset, HexValue
      def_property :resetsignal
      def_property :rclr
      def_property :rset
      def_property :onread
      def_property :woset
      def_property :woclr
      def_property :onwrite
      def_property :swwe
      def_property :swwel
      def_property :swmod
      def_property :swacc
      def_property :singlepulse
      def_property :we
      def_property :wel
      def_property :anded
      def_property :ored
      def_property :xored
      def_property :hwclr
      def_property :hwset
      def_property :hwenable
      def_property :hwmask
      def_property :encode, RefValue
      def_property :precedence
      def_property :paritycheck
    end
  end
end
