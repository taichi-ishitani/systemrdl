# frozen_string_literal: true

module SystemRDL
  module Model
    class << self
      def build(root)
        models = root.instances.map do |addrmap|
          AddrMap.new(addrmap, nil)
        end

        finalize(models)
        models
      end

      private

      def finalize(models)
        instances = models.flat_map { |model| collect_instances(model) }
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
        end
      end
    end
  end
end
