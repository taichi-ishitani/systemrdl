# frozen_string_literal: true

module SystemRDL
  class Parser
    class Parser < Parslet::Parser
    end

    class Context < Parslet::Context
      def initialize(bindings, transformer)
        super(bindings)
        @__transformer = transformer
      end

      def method_missing(method, *args, **kwargs, &block)
        if @__transformer.respond_to?(method, true)
          __define_delegator__(method)
          __send__(method, *args, **kwargs, &block)
        else
          super
        end
      end

      def respond_to_missing?(symbol, include_private)
        super || @__transformer.respond_to?(symbol, true)
      end

      private

      def __define_delegator__(method)
        self.class.class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def foo(...)
          #   @__transformer.__send__(:foo, ...)
          # end
          def #{method}(...)
            @__transformer.__send__(:#{method}, ...)
          end
        M
      end
    end

    class Transformer < Parslet::Transform
      def call_on_match(bindings, block)
        return unless block

        context = Context.new(bindings, self)
        context.instance_eval(&block)
      end
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
