# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestEnum < TestCase
      def test_enum_definition
        code = <<~'RDL'
          enum myAutoEnum { first_value ; second_value ; third_value ; } ;
          addrmap my_map {
            enum myAutoEnum { first_value ; second_value ; third_value ; } ;
          };
        RDL
        assert_parses(
          root(
            enum_def(
              'myAutoEnum',
              enum_entry_def('first_value'),
              enum_entry_def('second_value'),
              enum_entry_def('third_value')
            ),
            s(
              :component_named_def, 'addrmap',
              id('my_map'),
              enum_def(
                'myAutoEnum',
                enum_entry_def('first_value'),
                enum_entry_def('second_value'),
                enum_entry_def('third_value')
              )
            )
          ),
          code
        )

        code = <<~'RDL'
          enum myPartiallyAssignedEnum { a ; b ; c = 8'h6 ; d ; e = 8'h12 ; f ; } ;
        RDL
        assert_parses(
          root(
            enum_def(
              'myPartiallyAssignedEnum',
              enum_entry_def('a'),
              enum_entry_def('b'),
              enum_entry_def('c', s(:verilog_number, "8'h6")),
              enum_entry_def('d'),
              enum_entry_def('e', s(:verilog_number, "8'h12")),
              enum_entry_def('f')
            )
          ),
          code
        )

        code = <<~'RDL'
        enum myBitFieldEncoding {
          first_encoding_entry = 8'hab;
          second_entry = 8'hcd {
            name = "second entry";
          };
          third_entry = 8'hef {
            name = "third entry, just like others";
            desc = "this value has a special documentation";
          };
          fourth_entry = 8'b10010011;
        };
        RDL
        assert_parses(
          root(
            enum_def(
              'myBitFieldEncoding',
              enum_entry_def(
                'first_encoding_entry',
                s(:verilog_number, "8'hab")
              ),
              enum_entry_def(
                'second_entry',
                s(:verilog_number, "8'hcd"),
                s(:prop_assignment, id('name'), s(:string, '"second entry"'))
              ),
              enum_entry_def(
                'third_entry',
                s(:verilog_number, "8'hef"),
                s(:prop_assignment, id('name'), s(:string, '"third entry, just like others"')),
                s(:prop_assignment, id('desc'), s(:string, '"this value has a special documentation"'))
              ),
              enum_entry_def(
                'fourth_entry',
                s(:verilog_number, "8'b10010011")
              )
            )
          ),
          code
        )
      end

      def root(*children)
        s(:root, *children)
      end

      def enum_def(name, *children)
        s(:enum_def, id(name), *children)
      end

      def enum_entry_def(name, value = nil, *children)
        s(:enum_entry, *[id(name), value, *children].compact)
      end

      def id(name)
        s(:id, name.to_s)
      end
    end
  end
end
