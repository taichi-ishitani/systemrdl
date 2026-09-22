# frozen_string_literal: true

module SystemRDL
  module Model
    Signature = Data.define(:component_name, :parameter_hash) do
      class << self
        def generate(instance)
          return if instance.definition.anonymous_def?

          new(component_name(instance), parameter_hash(instance))
        end

        private

        def component_name(instance)
          instance.definition.upper_layers(include_self: true).map(&:id)
        end

        def parameter_hash(instance)
          return '' if instance.params.empty?

          Digest::MD5.hexdigest(concat_params(instance))
        end

        def concat_params(instance)
          params = instance.params.flat_map do |param|
            if param.value.type == :bit
              [param.value.to_s, param.value.width.to_s]
            else
              param.value.to_s
            end
          end
          params.join("\x1F") # Unit separator
        end
      end
    end
  end
end
