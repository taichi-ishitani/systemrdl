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

      def initialize(object, name, parent, token_range, model_map)
        model_map[object] = self
        @name = name
        @parent = parent
        @token_range = token_range
      end

      attr_reader :name
      attr_reader :parent
      attr_reader :token_range
      attr_reader :properties

      def property(prop_name)
        @properties[prop_name]
      end

      private

      def build_properties(object, model_map)
        self.class.properties&.to_h do |prop_name, (default_class, body)|
          prop_value, value_class, token_range =
            extract_property(object, prop_name, default_class, body)
          value = create_property_value(value_class, prop_name, prop_value, token_range, model_map)
          if (prop = get_property(object, prop_name))
            model_map[prop] = value
          end

          [prop_name, value]
        end
      end

      def extract_property(object, prop_name, default_class, body)
        if body
          value, klass = body.call(object)
          [value, klass || Value]
        else
          value = eval_prop_value(object, prop_name)
          klass = select_value_class(value, default_class)
          [value&.value, klass, value&.token_range]
        end
      end

      def get_property(object, prop_name)
        if prop_name == :display_name
          object.property(:name)
        else
          object.property(prop_name)
        end
      end

      def eval_prop_value(object, prop_name)
        if (prop = get_property(object, prop_name))
          prop.value
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

      def create_property_value(klass, name, value, token_range, model_map)
        prop_value = model_map[value] || value
        klass.new(name.to_s, prop_value, self, token_range)
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
