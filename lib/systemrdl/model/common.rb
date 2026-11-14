# frozen_string_literal: true

module SystemRDL
  module Model
    module Common
      module Extension
        attr_reader :properties

        private

        def def_property(prop_name, value_class = nil, &body)
          (@properties ||= {})[prop_name] = [value_class, body]
          class_eval(<<~PROP, __FILE__, __LINE__ + 1)
            # def display_name
            #   @properties[:display_name]&.value
            # end
            def #{prop_name}
              @properties[:#{prop_name}]&.value
            end
          PROP
        end
      end

      def self.included(klass)
        klass.extend(Extension)
      end

      def initialize(object, name, parent, token_range)
        @name = name
        @parent = parent
        @token_range = token_range
        @properties = build_properties(object).freeze
      end

      attr_reader :name
      attr_reader :parent
      attr_reader :token_range
      attr_reader :properties

      def property(prop_name)
        @properties[prop_name]
      end

      private

      def build_properties(object)
        self.class.properties&.to_h do |prop_name, (default_class, body)|
          prop_value, value_class, token_range =
            if body
              value, klass = body.call(object)
              [value, klass || Value]
            else
              value = eval_prop_value(prop_name, object)
              klass = select_value_class(value, default_class)
              [value&.value, klass, value&.token_range]
            end
          [prop_name, value_class.new(prop_name.to_s, prop_value, self, token_range)]
        end
      end

      def eval_prop_value(prop_name, object)
        if prop_name == :display_name
          object.property_value(:name)
        elsif (property = object.property(prop_name))
          property.value
        else
          object.__send__(prop_name)
        end
      end

      def select_value_class(value, default_class)
        if ref_value?(value)
          RefValue
        elsif default_class && value&.value
          default_class
        else
          Value
        end
      end

      def ref_value?(value)
        return false unless value.respond_to?(:type)

        value.type.kind in :prop_ref | :field_ref | :enum_ref
      end

      def pp_properties(pp)
        @properties&.each_value do |prop_value|
          pp.breakable
          pp.pp(prop_value)
        end
      end
    end
  end
end
