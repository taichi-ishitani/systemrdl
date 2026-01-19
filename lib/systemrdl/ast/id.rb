# frozen_string_literal: true

module SystemRDL
  module AST
    class ID < Base
      def initialize(range, token)
        super(:id, range, token)
      end
    end
  end
end
