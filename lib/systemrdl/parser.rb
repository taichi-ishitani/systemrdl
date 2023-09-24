# frozen_string_literal: true

module SystemRDL
  class Parser
    class << self
      include Parslet

      def parser
        @parser ||= Class.new(Parslet::Parser)
      end

      def transformer
        @transformer ||= Class.new(Parslet::Transform)
      end

      private

      def define_parser(&body)
        parser.class_exec(&body)
      end

      def define_transformer(&body)
        transformer.class_exec(&body)
      end
    end

    def initialize(root = nil)
      @root = root
    end

    def parse(string)
      tree = parser.parse(string)
      transformer.apply(tree)
    end

    private

    def parser
      parser = self.class.parser.new
      @root && parser.__send__(@root) || parser
    end

    def transformer
      self.class.transformer.new
    end
  end
end
