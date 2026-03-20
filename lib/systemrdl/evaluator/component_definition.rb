# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      include Common

      def initialize(id, elements, insts, range)
        super(range)
        @id = id
        @definitions = {}
        @elements = elements
        @insts = insts
      end

      attr_reader :id
      attr_reader :definitions

      def connect(parent, component)
        super
        @component.add_definition(self)
        @elements.each { |element| element.connect(self, self) }
        @insts&.connect(self, self)
      end

      def evaluate(instance, **optargs)
        @insts&.evaluate(instance, **optargs)
      end

      def create_instance(parent_instance, name, **optargs)
        parent_instance.add_child_instance(name) do |instance|
          init_properties(instance)
          @elements.each do |element|
            element.evaluate(instance, **optargs)
          end
        end
      end

      private

      def init_properties(instance)
        #
        # Table 5—Universal component properties
        #
        create_property(instance, :name, [:string], instance.name.to_s)
        create_property(instance, :desc, [:string], '')
      end

      def create_property(instance, name, types, value)
        property = Property.new(instance, name, types, value)
        instance.properties << property
      end

      protected

      def add_definition(definition)
        id = definition.id
        @definitions[id] = definition
      end
    end

    class Root < ComponentDefinition
      def initialize(elements, range)
        super(:root, elements, nil, range)
        connect(self, self)
      end

      def evaluate(instance, **optargs)
        @elements.each do |element|
          element.evaluate(instance, **optargs)
        end
      end
    end

    class AddrMapDefinition < ComponentDefinition
      def evaluate(instance, **optargs)
        create_instance(instance, @id, **optargs)
      end

      private

      def init_properties(instance)
        super

        #
        # Table 26—Address map properties
        #
        create_property(instance, :alignment, [:longint], nil)
        create_property(instance, :sharedextbus, [:boolean], false)
        create_property(instance, :errextbus, [:boolean], false)
        create_property(instance, :bigendian, [:boolean], false)
        create_property(instance, :littleendian, [:boolean], false)
        create_property(instance, :addressing, [:addressing_type], :regalign)
        create_property(instance, :rsvdset, [:boolean], false)
        create_property(instance, :rsvdsetX, [:boolean], false)
        create_property(instance, :msb0, [:boolean], false)
        create_property(instance, :lsb0, [:boolean], false)
      end
    end

    class RegFileDefinition < ComponentDefinition
      private

      def init_properties(instance)
        super

        #
        # Table 25—Register file properties
        #
        create_property(instance, :alignment, [:longint], nil)
        create_property(instance, :sharedextbus, [:boolean], false)
        create_property(instance, :errextbus, [:boolean], false)
      end
    end

    class RegDefinition < ComponentDefinition
      private

      def init_properties(instance)
        super

        #
        # Table 23—Register properties
        #
        create_property(instance, :regwidth, [:longint], nil)
        create_property(instance, :accesswidth, [:longint], nil)
        create_property(instance, :errextbus, [:boolean], false)
        create_property(instance, :shared, [:boolean], false)
      end
    end

    class FieldDefinition < ComponentDefinition
      private

      def init_properties(instance)
        super

        #
        # Table 11—Field access properties
        #
        create_property(instance, :hw, [:access_type], :rw)
        create_property(instance, :sw, [:access_type], :rw)

        #
        # Table 13—Hardware signal properties
        #
        create_property(instance, :next, [:reference], nil)
        create_property(instance, :reset, [:bit, :reference], nil)
        create_property(instance, :resetsignal, [:reference], nil)

        #
        # Table 14—Software access properties
        #
        create_property(instance, :rclr, [:boolean], false)
        create_property(instance, :rset, [:boolean], false)
        create_property(instance, :onread, [:on_read_type], nil)
        create_property(instance, :woset, [:boolean], false)
        create_property(instance, :woclr, [:boolean], false)
        create_property(instance, :onwrite, [:on_write_type], nil)
        create_property(instance, :swwe, [:boolean, :reference], false)
        create_property(instance, :swwel, [:boolean, :reference], false)
        create_property(instance, :swmod, [:boolean], false)
        create_property(instance, :swacc, [:boolean], false)
        create_property(instance, :singlepulse, [:boolean], false)

        #
        # Table 18—Hardware access properties
        #
        create_property(instance, :we, [:boolean, :reference], false)
        create_property(instance, :wel, [:boolean, :reference], false)
        create_property(instance, :anded, [:boolean], false)
        create_property(instance, :ored, [:boolean], false)
        create_property(instance, :xored, [:boolean], false)
        create_property(instance, :fieldwidth, [:longint], nil)
        create_property(instance, :hwclr, [:boolean, :reference], false)
        create_property(instance, :hwset, [:boolean, :reference], false)
        create_property(instance, :hwenable, [:reference], nil)
        create_property(instance, :hwmask, [:reference], nil)

        #
        # Table 19—Counter field properties
        #
        # TODO

        #
        # Table 21—Field access interrupt properties
        #
        # TODO

        #
        # Table 22—Miscellaneous properties
        #
        # create_property(:encode) TODO
        create_property(instance, :precedence, [:precedence_type], :sw)
        create_property(instance, :paritycheck, [:boolean], false)
      end
    end
  end
end
