# frozen_string_literal: true

module SystemRDL
  module Model
    class << self
      def build(root)
        model = Root.new(root, nil)
        finalize(model)
        model
      end

      private

      def finalize(model)
        instances = collect_instances(model)
        properties = instances.flat_map { |inst| inst.properties.values }

        properties.each do |property|
          resolve_reference(property, instances, properties)
          property.freeze
        end
      end

      def collect_instances(model)
        model.instances.flat_map { |inst| [inst, *collect_instances(inst)] }
      end

      def resolve_reference(property, instances, properties)
        return if property.value?

        path = property.value.full_name

        if (ref = instances.find { |inst| inst.full_name == path })
          property.value = ref
          return
        end

        if (ref = properties.find { |prop| prop.full_name == path })
          property.value = ref
          return
        end

        if (ref = resolve_type_ref(property))
          property.value = ref
        end
      end

      def resolve_type_ref(property)
        return unless property.value.kind == :enum

        type_name = property.value.name.to_s
        property.instance.hierarchy.reverse_each do |inst|
          type = inst.types.find { |t| t.name == type_name }
          return type if type
        end

        nil
      end
    end
  end
end
