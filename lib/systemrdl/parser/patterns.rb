# frozen_string_literal: true

module SystemRDL
  module Parser
    module Patterns
      WHITE_SPACES = /[ \t\n\r]+/

      LINE_COMMENT = %r{//.*$}
      BLOCK_COMMENT = %r{/\*(?:(?!\*/).)*\*/}m
      UNTERMINATED_BLOCK_COMMENT = %r{/\*(?:(?!\*/).)*}m

      DIRECTIVES =
        [
          'ifdef', 'ifndef', 'elsif', 'else', 'endif', 'define'
        ].to_h { |d| ["`#{d}", :"pp_#{d}".upcase] }.freeze
      KEYWORDS =
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
        ].to_h { |kw| [kw, :"kw_#{kw}".upcase] }.freeze
      SYMBOLS =
        [
          '[', ']', '(', ')', '{', '}',
          '!', '&&', '||', '<', '>', '<=', '>=', '==', '!=', '>>', '<<',
          '~', '&', '~&', '|', '~|', '^', '~^', '^~', '*', '/', '%', '+', '-', '**',
          '?', ':', '->', '.', ',', "'", ';', '=', '@', '+=', '%='
        ].sort_by(&:size).reverse.to_h { |sym| [Regexp.new(Regexp.quote(sym)), sym] }.freeze

      VERILOG_BIN_NUMBER = /(\d+)'[bB]([01][01_]*)/
      VERILOG_DEC_NUMBER = /(\d+)'[dD](\d[\d_]*)/
      VERILOG_HEX_NUMBER = /(\d+)'[hH](\h[\h_]*)/

      DEC_NUMBER = /\d[\d_]*/
      HEX_NUMBER = /0[xX]\h[\h_]*/

      NUMBERS = {
        VERILOG_HEX_NUMBER => :VERILOG_NUMBER,
        VERILOG_DEC_NUMBER => :VERILOG_NUMBER,
        VERILOG_BIN_NUMBER => :VERILOG_NUMBER,
        HEX_NUMBER => :NUMBER,
        DEC_NUMBER => :NUMBER
      }.freeze
    end
  end
end
