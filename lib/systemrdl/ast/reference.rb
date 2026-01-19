# frozen_string_literal: true

module SystemRDL
  module AST
    class InstanceRef < Base
      def initialize(range, *elements)
        super(:instance_ref, range, *elements)
      end
    end

    class InstanceRefElement < Base
      def initialize(range, id, *array)
        super(:instance_ref_element, range, id, *array)
      end
    end

    class PropRef < Base
      def initialize(range, instance_ref, prop_id)
        super(:prop_ref, range, instance_ref, prop_id)
      end
    end
  end
end
