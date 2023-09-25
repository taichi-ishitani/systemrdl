# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      private

      def keyword(word)
        str(word) >> match('\\w').absent?
      end

      def keywords(*words)
        words
          .map { |w| str(w) }
          .inject(:|)
          .then { |atom| atom >> match('\\w').absent? }
      end
    end
  end
end
