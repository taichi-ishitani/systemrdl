# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module BuiltinProperties
      class << self
        attr_reader :properties

        def find(name)
          properties.find { |prop| prop.name == name }
        end

        private

        def def_property(name, &)
          @properties ||= []
          @properties << PropertyDefinition.new(name, &)
        end
      end

      #
      # Table G1—Property cross-reference
      #
      def_property :accesswidth do |prop|
        prop.targets = [:reg]
        prop.types = [:longint]
      end

      def_property :addressing do |prop|
        prop.targets = [:addrmap]
        prop.types = [:addressingtype]
        prop.dynamic_assign = false
        prop.default_value = :regalign
      end

      def_property :alignment do |prop|
        prop.targets = [:addrmap, :regfile]
        prop.types = [:longint]
        prop.dynamic_assign = false
      end

      def_property :anded do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :bigendian do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = true
        prop.default_value = false
      end

      def_property :desc do |prop|
        prop.types = [:string]
        prop.dynamic_assign = true
        prop.default_value = proc { '' }
      end

      def_property :errextbus do |prop|
        prop.targets = [:addrmap, :regfile, :reg]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :fieldwidth do |prop|
        prop.targets = [:field]
        prop.types = [:longint]
      end

      def_property :hw do |prop|
        prop.targets = [:field]
        prop.types = [:accesstype]
        prop.default_value = :rw
      end

      def_property :hwclr do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :hwenable do |prop|
        prop.targets = [:field]
        prop.types = [:field_reference, :property_reference]
      end

      def_property :hwmask do |prop|
        prop.targets = [:field]
        prop.types = [:field_reference, :property_reference]
      end

      def_property :hwset do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :littleendian do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = true
        prop.default_value = false
      end

      def_property :lsb0 do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :msb0 do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :name do |prop|
        prop.types = [:string]
        prop.dynamic_assign = true
        prop.default_value = proc { |inst| inst.name.to_s }
      end

      def_property :next do |prop|
        prop.targets = [:field]
        prop.types = [:field_reference, :property_reference]
      end

      def_property :onread do |prop|
        prop.targets = [:field]
        prop.types = [:onreadtype]
      end

      def_property :onwrite do |prop|
        prop.targets = [:field]
        prop.types = [:onwritetype]
      end

      def_property :ored do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :paritycheck do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :precedence do |prop|
        prop.targets = [:field]
        prop.types = [:precedencetype]
        prop.default_value = :sw
      end

      def_property :rclr do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :regwidth do |prop|
        prop.targets = [:reg]
        prop.types = [:longint]
        prop.default_value = 32
      end

      def_property :reset do |prop|
        prop.targets = [:field]
        prop.types = [:bit, :field_reference, :property_reference]
      end

      def_property :resetsignal do |prop|
        prop.targets = [:field]
        prop.types = [:field_reference, :property_reference]
      end

      def_property :rset do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :rsvdset do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :rsvdsetX do |prop|
        prop.targets = [:addrmap]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :shared do |prop|
        prop.targets = [:reg]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :sharedextbus do |prop|
        prop.targets = [:addrmap, :regfile]
        prop.types = [:boolean]
        prop.dynamic_assign = false
        prop.default_value = false
      end

      def_property :singlepulse do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :sw do |prop|
        prop.targets = [:field]
        prop.types = [:accesstype]
        prop.default_value = :rw
      end

      def_property :swacc do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :swmod do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :swwe do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :swwel do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :we do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :wel do |prop|
        prop.targets = [:field]
        prop.types = [:boolean, :field_reference, :property_reference]
        prop.default_value = false
      end

      def_property :woclr do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :woset do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end

      def_property :xored do |prop|
        prop.targets = [:field]
        prop.types = [:boolean]
        prop.default_value = false
      end
    end
  end
end
