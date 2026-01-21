# frozen_string_literal: true

module SystemRDL
  module Parser
    class Node < AST::Node
      attr_reader :range

      def replace_range(range)
        updated(nil, nil, { range: range })
      end
    end
  end
end
