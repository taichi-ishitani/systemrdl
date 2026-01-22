# frozen_string_literal: true

module SystemRDL
  module Parser
    class Scanner
      include RaiseParseError

      class << self
        private

        def keyword_patterns
          [
            'abstract', 'accesstype', 'addressingtype', 'addrmap', 'alias',
            'all', 'bit', 'boolean', 'bothedge', 'compact',
            'component', 'componentwidth', 'constraint', 'default', 'encode',
            'enum', 'external', 'false', 'field', 'fullalign',
            'hw', 'inside', 'internal', 'level', 'longint',
            'mem', 'na', 'negedge', 'nonsticky', 'number',
            'onreadtype', 'onwritetype', 'posedge', 'property', 'r',
            'rclr', 'ref', 'reg', 'regalign', 'regfile',
            'rset', 'ruser', 'rw', 'rw1', 'signal',
            'string', 'struct', 'sw', 'this', 'true',
            'type', 'unsigned', 'w', 'w1', 'wclr',
            'woclr', 'woset', 'wot', 'wr', 'wset',
            'wuser', 'wzc', 'wzs', 'wzt'
          ].to_h { |kw| [kw, kw.upcase.to_sym] }.freeze
        end

        def symbol_patterns
          patterns = [
            '[', ']', '(', ')', '{', '}',
            '!', '&&', '||', '<', '>', '<=', '>=', '==', '!=', '>>', '<<',
            '~', '&', '~&', '|', '~|', '^', '~^', '^~', '*', '/', '%', '+', '-', '**',
            '?', ':', '->', '.', ','
          ]
          patterns
            .sort_by(&:size)
            .reverse
            .to_h { |pattern| [Regexp.new(Regexp.escape(pattern)), pattern] }
            .freeze
        end
      end

      WHITE_SPACES = /[ \t\n\r]+/

      KEYWORDS = keyword_patterns

      SYMBOLS = symbol_patterns

      NUMBERS = {
        /\d+'[hH]\h[\h_]*/ => :VERILOG_NUMBER,
        /\d+'[dD]\d[\d_]*/ => :VERILOG_NUMBER,
        /\d+'[bB][01][01_]*/ => :VERILOG_NUMBER,
        /0[xX]\h[\h_]*/ => :NUMBER,
        /\d[\d_]*/ => :NUMBER
      }.freeze

      def initialize(code, filename)
        @ss = StringScanner.new(code)
        @filename = filename
        @line = 1
        @column = 1
      end

      def next_token
        token = scan_next_token
        token && [token.kind, token]
      end

      private

      def eos?
        @ss.eos?
      end

      def scan(pattern)
        text = @ss.scan(pattern)
        return unless text

        line = @line
        column = @column
        update_state(text)

        [text, line, column]
      end

      def scan_token(kind, pattern)
        text, line, column = scan(pattern)
        text && create_token(kind, text, line, column)
      end

      def peek(pattern)
        @ss.check(pattern)
      end

      def peek_char
        peek(/./m)
      end

      def advance(text)
        @ss.pos += text.bytesize
        update_state(text)
      end

      def update_state(text)
        return if text.empty?

        n_newline = text.count("\n")
        @line += n_newline

        @column =
          if text[-1] == "\n"
            1
          elsif n_newline > 0
            last = text.lines.last
            last.length
          else
            @column + text.length
          end
      end

      def create_token(kind, text, line, column)
        position = Position.new(@filename, line, column)
        Token.new(text, kind, position)
      end

      def current_position
        Position.new(@filename, @line, @column)
      end

      def scan_next_token
        return if eos?

        skip_blank

        token = scan_string
        return token if token

        token = scan_number
        return token if token

        token = scan_symbol
        return token if token

        token = scan_word
        return token if token

        char = peek_char
        raise_parse_error "illegal character `#{char}`", current_position
      end

      def skip_blank
        scan(WHITE_SPACES)
      end

      def scan_string
        return unless peek(/"/)

        line = @line
        column = @column

        buffer = []
        while (char = peek_char)
          advance(char)
          if char == '\\' && ((next_char, _, _) = scan(/"/))
            buffer << next_char
          else
            buffer << char
            break if buffer.size >= 2 && buffer.last == '"'
          end
        end

        text = buffer.join
        create_token(:STRING, text, line, column)
      end

      def scan_number
        NUMBERS.each do |pattern, kind|
          token = scan_token(kind, pattern)
          return token if token
        end

        nil
      end

      def scan_symbol
        SYMBOLS.each do |pattern, kind|
          token = scan_token(kind, pattern)
          return token if token
        end

        nil
      end

      def scan_word
        text, line, column = scan(/[_a-zA-Z]\w*/)
        return unless text

        KEYWORDS.each do |pattern, kind|
          next if text != pattern

          token = create_token(kind, text, line, column)
          return token
        end

        create_token(:SIMPLE_ID, text, line, column)
      end
    end
  end
end
