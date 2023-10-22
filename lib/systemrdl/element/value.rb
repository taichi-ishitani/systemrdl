# frozen_string_literal: true

module SystemRDL
  module Element
    class Value < ::SimpleDelegator
      def initialize(value, data_type, position = nil)
        super(value)
        @data_type = data_type
        @position = position
      end

      attr_reader :data_type
      attr_reader :position
    end

    class BooleanValue < Value
      def initialize(value, position = nil)
        super(value, :boolean, position)
      end

      def to_i
        __getobj__ ? 1 : 0
      end

      def to_boolean
        __getobj__
      end
    end

    class NumberValue < Value
      def initialize(value, width, position = nil)
        super(value[0, width], :number, position)
        @width = width
      end

      attr_reader :width

      def to_boolean
        !zero?
      end
    end

    class StringValue < Value
      def initialize(value, position = nil)
        super(value, :string, position)
      end
    end

    class TypeEnumValue < Value
      class << self
        private

        def define_type_checkers(types)
          types.each do |type|
            class_eval(<<~M, __FILE__, __LINE__ + 1)
              # def foo_type?
              #   match_type?(:foo)
              # end
              def #{type}_type?
                match_type?(:#{type})
              end
            M
          end
        end
      end

      def match_type?(type)
        __getobj__ == type
      end
    end

    class AccessTypeValue < TypeEnumValue
      def initialize(value, position = nil)
        super(value, :accesstype, position)
      end

      define_type_checkers [:na, :r, :w, :rw1, :w1]

      def rw_type?
        match_type?(:rw) || match_type?(:wr)
      end

      alias_method :wr_type?, :rw_type?
    end

    class OnreadtypeValue < TypeEnumValue
      def initialize(value, position = nil)
        super(value, :onreadtype, position)
      end

      define_type_checkers [:rclr, :rset, :ruser]
    end

    class OnwritetypeValue < TypeEnumValue
      def initialize(value, position = nil)
        super(value, :onwritetype, position)
      end

      define_type_checkers [
        :woset, :woclr, :wot, :wzs, :wzc, :wzt,
        :wclr, :wset, :wuser
      ]
    end

    class AddressingtypeValue < TypeEnumValue
      def initialize(value, position = nil)
        super(value, :addressingtype, position)
      end

      define_type_checkers [:compact, :regalign, :fullalign]
    end

    class PrecedencetypeValue < TypeEnumValue
      def initialize(value, position = nil)
        super(value, :precedencetype, position)
      end

      define_type_checkers [:hw, :sw]
    end
  end
end
