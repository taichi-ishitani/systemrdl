# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_reference_element(node, context)
      { id: node.id, array: process_all(node.array, context) }
    end

    def on_reference(node, context)
      ref_elements = process_all(node.instance_refernce, context)

      instances = find_instances(ref_elements, [context])
      return instances if !instances.empty? && !node.property

      properties = find_properties(node, context, ref_elements, instances)
      return properties if properties && !properties.empty?

      error "the given reference is not found: #{node}", node.position
    end

    def find_instances(ref_elements, contexts)
      return contexts unless ref_elements

      instances =
        contexts.flat_map do |component|
          component
            .components
            .select { |child| match_component?(child, ref_elements.first) }
        end
      if ref_elements.size > 1
        find_instances(ref_elements[1..], instances.compact)
      else
        instances.compact
      end
    end

    def match_component?(component, ref_element)
      component.instance_name == ref_element[:id].id &&
        (!ref_element[:array] || component.array == ref_element[:array])
    end

    def find_properties(node, context, ref_elements, instances)
      contexts, property_name =
        if !instances.empty? && node.property
          [instances, node.property]
        else
          [[context], extract_property_name(ref_elements)]
        end
      property_name &&
        contexts
          .map { find_property(property_name, _1) }
          .compact
    end

    def extract_property_name(ref_elements)
      ref_elements.size == 1 && !ref_elements.first[:array] &&
        ref_elements.first[:id] || nil
    end

    def find_property(property_name, context)
      context.properties.find { |property| property.name == property_name.id }
    end
  end
end
