# frozen_string_literal: true

module SystemRDL
  class Parser
    KEYWORDS = [
      'abstract', 'accesstype', 'addressingtype', 'addrmap', 'alias', 'all', 'bit',
      'boolean', 'bothedge', 'compact', 'component', 'componentwidth', 'constraint',
      'default', 'encode', 'enum', 'external', 'false', 'field', 'fullalign', 'hw',
      'inside', 'internal', 'level', 'longint', 'mem', 'na', 'negedge', 'nonsticky',
      'number', 'onreadtype', 'onwritetype', 'posedge', 'property', 'r', 'rclr', 'ref',
      'reg', 'regalign', 'regfile', 'rset', 'ruser', 'rw', 'rw1', 'signal', 'string',
      'struct', 'sw', 'this', 'true', 'type', 'unsigned', 'w', 'w1', 'wclr', 'woclr',
      'woset', 'wot', 'wr', 'wset', 'wuser', 'wzc', 'wzs', 'wzt'
    ].freeze

    RESERVED_WORDS = [
      'alternate', 'byte', 'int', 'precedencetype', 'real',
      'shortint', 'shortreal', 'signed', 'with', 'within'
    ].freeze

    define_parser do
      KEYWORDS.each do |kw|
        rule("kw_#{kw}".to_sym) do
          str(kw) >> match('\\w').absent?
        end
      end

      rule(:any_keyword) do
        KEYWORDS
          .sort_by(&:length).reverse
          .map { |kw| str(kw) }.inject(:|).then { |atom| atom >> match('\\w').absent? }
      end

      RESERVED_WORDS.each do |rw|
        rule("rw_#{rw}".to_sym) do
          str(rw) >> match('\\w').absent?
        end
      end

      rule(:any_reserved_word) do
        RESERVED_WORDS
          .sort_by(&:length).reverse
          .map { |rw| str(rw) }.inject(:|).then { |atom| atom >> match('\\w').absent? }
      end
    end
  end
end
