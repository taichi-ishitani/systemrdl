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

      def to_token_range(values)
        values = values.compact
        head = values.first
        tail = values.last
        if values.size == 1 && head.is_a?(Node)
          head.token_range
        else
          head_token = (head.is_a?(Node) && head.token_range.head) || head
          tail_token = (tail.is_a?(Node) && tail.token_range.tail) || tail
          TokenRange.new(head_token, tail_token)
        end
      end
    end
  end
end
