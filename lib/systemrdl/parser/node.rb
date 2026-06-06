# frozen_string_literal: true

module SystemRDL
  module Parser
    class Node < AST::Node
      attr_reader :token_range

      def replace_type(type)
        updated(type, nil, nil)
      end

      def replace_token_range(token_range)
        updated(nil, nil, { token_range: token_range })
      end
    end
  end
end
