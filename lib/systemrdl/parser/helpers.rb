# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      private

      def keyword(word)
        str(word) >> match('\w').absent?
      end
    end
  end
end
