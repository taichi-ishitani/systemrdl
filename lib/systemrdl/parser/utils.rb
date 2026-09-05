# frozen_string_literal: true

module SystemRDL
  module Parser
    module Utils
      module_function

      def calc_next_position(text, line, column)
        return [line, column] if text.empty?

        n_nl = text.count("\n")
        line_next = line + n_nl

        column_next =
          if /\R\z/.match?(text)
            1
          elsif n_nl > 0
            last = text.lines.last
            last.length
          else
            column + text.length
          end

        [line_next, column_next]
      end
    end
  end
end
