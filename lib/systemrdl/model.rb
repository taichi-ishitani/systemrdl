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
        proeprties = instances.flat_map { |inst| inst.properties.values }

        proeprties.each do |property|
          resolve_reference(property, instances, proeprties)
          property.freeze
        end
      end

      def collect_instances(model)
        model.instances.flat_map { |inst| [inst, *collect_instances(inst)] }
      end

      def resolve_reference(property, instances, proeprties)
        return if property.value?

        path = property.value.full_name

        if (ref = instances.find { |inst| inst.full_name == path })
          property.value = ref
          return
        end

        if (ref = proeprties.find { |prop| prop.full_name == path })
          property.value = ref
        end
      end
    end
  end
end
