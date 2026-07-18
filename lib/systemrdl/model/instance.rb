# frozen_string_literal: true

module SystemRDL
  module Model
    class Instance
      def initialize(inst, parent)
        @name = inst.element_name
        @layer = inst.layer
        @parent = parent
        @instances = build_sub_instances(inst)
        @properties = build_properties(inst)
        @token_range = inst.token_range
        freeze
      end

      attr_reader :name
      attr_reader :layer
      attr_reader :parent
      attr_reader :instances
      attr_reader :token_range

      class << self
        attr_reader :properties

        private

        def def_property(property_name)
          (@properties ||= []) << property_name
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

      def_property :display_name
      def_property :desc

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
          when :regfile then RegFile.new(sub_inst, self)
          when :reg then Reg.new(sub_inst, self)
          when :field then Field.new(sub_inst, self)
          end
        end
      end

      def build_properties(inst)
        properties.to_h do |prop_name|
          prop_value =
            if prop_name == :display_name
              inst.property_value(:name)
            elsif (property = inst.property(prop_name))
              property.value
            else
              inst.__send__(prop_name)
            end
          [prop_name, create_property_value(prop_name, prop_value)]
        end
      end

      def properties
        klass = self.class
        [klass.superclass, klass].flat_map(&:properties)
      end

      def create_property_value(name, value)
        klass =
          if reference_value?(value)
            ReferenceValue
          elsif hex_value?(name, value)
            HexValue
          else
            Value
          end
        klass.new(name.to_s, value&.value, self, value&.token_range)
      end

      def reference_value?(value)
        return false unless value

        value.type in :property_reference | :field_reference
      end

      def hex_value?(_name, _value)
        false
      end
    end

    class AddrMap < Instance
      def_property :sharedextbus
      def_property :errextbus
      def_property :bigendian
      def_property :littleendian
      def_property :rsvdset
      def_property :rsvdsetX

      alias_method :regs, :instances
    end

    class Reg < Instance
      def_property :address
      def_property :accesswidth
      def_property :errextbus
      def_property :shared

      alias_method :fields, :instances

      private

      def hex_value?(name, _value)
        name == :address
      end
    end

    class Field < Instance
      def_property :msb
      def_property :lsb
      def_property :hw
      def_property :sw
      def_property :next
      def_property :reset
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

      private

      def hex_value?(name, value)
        name == :reset && value&.type == :bit
      end
    end
  end
end
