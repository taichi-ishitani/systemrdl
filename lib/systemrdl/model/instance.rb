# frozen_string_literal: true

module SystemRDL
  module Model
    class Instance
      def initialize(inst, parent)
        @name = inst.element_name
        @layer = inst.layer
        @parent = parent
        @instances = build_sub_instances(inst).freeze
        @properties = build_properties(inst).freeze
        @token_range = inst.token_range
        freeze
      end

      attr_reader :name
      attr_reader :layer
      attr_reader :parent
      attr_reader :instances
      attr_reader :properties
      attr_reader :token_range

      class << self
        attr_reader :properties

        private

        def def_property(property_name, value_class = nil, &body)
          (@properties ||= {})[property_name] = [value_class, body]
          class_eval(<<~M, __FILE__, __LINE__ + 1)
            # def display_name
            #   @properties[:display_name]&.value
            # end
            def #{property_name}
              @properties[:#{property_name}]&.value
            end
          M
        end
      end

      def to_s
        "#{name} (#{layer})"
      end

      def full_name
        elements = [self]
        current = @parent
        while current
          elements.unshift(current)
          current = current.parent
        end

        elements.map(&:name).join('.')
      end

      def pretty_print(pp)
        pp.group(2, "#{self} {", '}') do
          @properties.each_value do |prop_value|
            pp.breakable
            pp.pp(prop_value)
          end
          @instances.each do |inst|
            pp.breakable
            pp.pp(inst)
          end
        end
      end

      def property(property_name)
        @properties[property_name]
      end

      private

      def build_sub_instances(inst)
        inst.instances.map do |sub_inst|
          case sub_inst.layer
          when :addrmap then AddrMap.new(sub_inst, self)
          when :mem then Mem.new(sub_inst, self)
          when :regfile then RegFile.new(sub_inst, self)
          when :reg then Reg.new(sub_inst, self)
          when :field then Field.new(sub_inst, self)
          end
        end
      end

      def build_properties(inst)
        self.class.properties.to_h do |prop_name, (default_class, body)|
          prop_value, prop_value_class, token_range =
            if body
              value, klass = body.call(inst)
              [value, klass || Value]
            else
              value = eval_prop_value(prop_name, inst)
              klass = select_value_class(value, default_class)
              [value&.value, klass, value&.token_range]
            end
          [prop_name, prop_value_class.new(prop_name.to_s, prop_value, self, token_range)]
        end
      end

      def eval_prop_value(prop_name, inst)
        if prop_name == :display_name
          inst.property_value(:name)
        elsif (property = inst.property(prop_name))
          property.value
        else
          inst.__send__(prop_name)
        end
      end

      def select_value_class(value, default_class)
        if reference_value?(value)
          ReferenceValue
        elsif default_class && value&.value
          default_class
        else
          Value
        end
      end

      def reference_value?(value)
        return false unless value.respond_to?(:type)

        value.type in :property_reference | :field_reference
      end
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
      def_property :precedence
      def_property :paritycheck
    end
  end
end
