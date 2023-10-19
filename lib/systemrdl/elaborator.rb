# frozen_string_literal: true

module SystemRDL
  class Elaborator
    def process(node, context)
      handler = :"on_#{node.type}"
      __send__(handler, node, context)
    end

    private

    def error(message, position)
      raise ElaborationError.new(message, position)
    end
  end
end
