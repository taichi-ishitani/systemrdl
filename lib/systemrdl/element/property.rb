# frozen_string_literal: true

module SystemRDL
  module Element
    class Property
      def initialize(component, name, type, position = nil)
        @component = component
        @name = name
        @type = type
        @position = position
      end

      attr_reader :component
      attr_reader :name
      attr_reader :type
      attr_reader :position
    end
  end
end
