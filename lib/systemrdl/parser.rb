# frozen_string_literal: true

module SystemRDL
  class Parser
    class Parser < Parslet::Parser
    end

    class Transformer < Parslet::Transform
    end

    class << self
      private

      def define_parser(&body)
        Parser.class_exec(&body)
      end

      def define_transformer(&body)
        Transformer.class_exec(&body)
      end
    end

    def initialize(root = nil)
      @root = root
    end

    def parse(string)
      tree = parser.parse(string)
      transformer.apply(tree)
    end

    def inspect
      parser.inspect
    end

    private

    def parser
      @parser ||= Parser.new
      @root && @parser.__send__(@root) || @parser
    end

    def transformer
      @transformer ||= Transformer.new
    end
  end
end
