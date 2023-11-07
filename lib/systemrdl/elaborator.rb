# frozen_string_literal: true

module SystemRDL
  class Elaborator
    def process(node, context)
      handler = :"on_#{node.type}"
      if respond_to?(handler, true)
        __send__(handler, node, context)
      else
        node
      end
    end

    def process_all(nodes, context)
      nodes&.map { |node| process(node, context) }
    end

    private

    def error(message, position)
      raise ElaborationError.new(message, position)
    end
  end
end
