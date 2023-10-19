# frozen_string_literal: true

module SystemRDL
  module Element
    class Value < ::SimpleDelegator
      def initialize(data_type, value)
        super(value)
        @data_type = data_type
      end

      attr_reader :data_type
    end

    class NumberValue < Value
      def initialize(data_type, value, width)
        super(data_type, value)
        @width = width
      end

      attr_reader :width
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
      def initialize(value)
        super(:accesstype, value)
      end

      define_type_checkers [:na, :r, :w, :rw1, :w1]

      def rw_type?
        match_type?(:rw) || match_type?(:wr)
      end

      alias_method :wr_type?, :rw_type?
    end

    class OnreadtypeValue < TypeEnumValue
      def initialize(value)
        super(:onreadtype, value)
      end

      define_type_checkers [:rclr, :rset, :ruser]
    end

    class OnwritetypeValue < TypeEnumValue
      def initialize(value)
        super(:onwritetype, value)
      end

      define_type_checkers [
        :woset, :woclr, :wot, :wzs, :wzc, :wzt,
        :wclr, :wset, :wuser
      ]
    end

    class AddressingtypeValue < TypeEnumValue
      def initialize(value)
        super(:addressingtype, value)
      end

      define_type_checkers [:compact, :regalign, :fullalign]
    end

    class PrecedencetypeValue < TypeEnumValue
      def initialize(value)
        super(:precedencetype, value)
      end

      define_type_checkers [:hw, :sw]
    end
  end
end
