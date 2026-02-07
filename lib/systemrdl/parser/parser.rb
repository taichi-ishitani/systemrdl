# frozen_string_literal: true

module SystemRDL
  module Parser
    class Parser < GeneratedParser
      include RaiseParseError

      def initialize(scanner, debug: false)
        @scanner = scanner
        @yydebug = debug
        super()
      end

      def parse
        do_parse
      end

      private

      def next_token
        @scanner.next_token
      end

      def on_error(_token_id, value, _value_stack)
        parse_error(value)
      end

      def parse_error(value)
        message = "syntax error on value '#{value.text}' (#{value.kind})"
        raise_parse_error message, value.position
      end

      def to_list(values, include_separator:)
        if include_separator
          [values[0], *values[1]&.map { |_, value| value }]
        else
          [values[0], *values[1]]
        end
      end

      def node(kind, children, values)
        range = to_token_range(values)
        Node.new(kind, children, { range: range })
      end

      def component_insts_node(type, insts)
        case type&.kind
        when :EXTERNAL then insts.replace_type(:external_component_insts)
        when :INTERNAL then insts.replace_type(:internal_component_insts)
        end
      end

      def component_inst_node(values)
        array, range = values[1]
        node(:component_inst, [values[0], *array, range, *values[2..]].compact, values)
      end

      def uop_node(values)
        node(:unary_operation, values, values)
      end

      def bop_node(values)
        node(:binary_operation, [values[1], values[0], values[2]], values)
      end

      def to_token_range(values)
        values = values.compact
        head = values.first
        tail = values.last
        if values.size == 1 && head.is_a?(Node)
          head.range
        else
          head_token = (head.is_a?(Node) && head.range.head) || head
          tail_token = (tail.is_a?(Node) && tail.range.tail) || tail
          TokenRange.new(head_token, tail_token)
        end
      end
    end
  end
end
