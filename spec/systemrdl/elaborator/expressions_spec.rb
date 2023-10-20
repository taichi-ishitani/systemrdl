# frozen_string_literal: true

RSpec.describe SystemRDL::Elaborator do
  context 'when a type based cast operation is given' do
    it 'should convert type of the expression to the specified type' do
      ['true', "2'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "boolean'(#{value})"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', "2'd0", "0"].each do |value|
        expect(elaborate(constant_expression: "boolean'(#{value})"))
          .to match_value(false, data_type: :boolean)
      end

      [['true', 1], ['false', 0]].each do |boolean_value, value|
        expect(elaborate(constant_expression: "bit'(#{boolean_value})"))
          .to match_number(value, width: 1)
        expect(elaborate(constant_expression: "longint'(#{boolean_value})"))
          .to match_number(value)
      end

      expect(elaborate(constant_expression: "bit'(4'h0)"))
        .to match_number(0, width: 4)
      expect(elaborate(constant_expression: "bit'(0)"))
        .to match_number(0, width: 64)
      expect(elaborate(constant_expression: "longint'(4'h0)"))
        .to match_number(0)
      expect(elaborate(constant_expression: "longint'(0)"))
        .to match_number(0)

      expect(elaborate(constant_expression: "bit'(4'hF)"))
        .to match_number(0xF, width: 4)
      expect(elaborate(constant_expression: "bit'(0xF)"))
        .to match_number(0xF, width: 64)
      expect(elaborate(constant_expression: "longint'(4'hF)"))
        .to match_number(0xF)
      expect(elaborate(constant_expression: "longint'(0xF)"))
        .to match_number(0xF)

      expect(elaborate(constant_expression: "bit'(65'h0_FFFF_FFFF_FFFF_FFFF)"))
        .to match_number(0xFFFF_FFFF_FFFF_FFFF, width: 65)
      expect(elaborate(constant_expression: "longint'(65'h0_FFFF_FFFF_FFFF_FFFF)"))
        .to match_number(0xFFFF_FFFF_FFFF_FFFF)
      expect(elaborate(constant_expression: "bit'(65'h1_0000_0000_0000_0000)"))
        .to match_number(0x1_0000_00000000_0000, width: 65)
      expect(elaborate(constant_expression: "longint'(65'h1_0000_0000_0000_0000)"))
        .to match_number(0)

      expect(elaborate(constant_expression: "boolean'(bit'(65'h1_0000_0000_0000_0000))"))
        .to match_value(true, data_type: :boolean)
      expect(elaborate(constant_expression: "boolean'(longint'(65'h1_0000_0000_0000_0000))"))
        .to match_value(false, data_type: :boolean)
    end

    context 'and the given expression is not an integral value' do
      it 'should raise ElaborationError' do
        {
          string: '"this is a string"',
          accesstype: 'na', addressingtype: 'compact', onreadtype: 'rclr', onwritetype: 'woset'
        }.each do |type, value|
          expect { elaborate(constant_expression: "boolean'(#{value})") }
            .to raise_elaboration_error "the given expression should be an integral value: #{type}"
          expect { elaborate(constant_expression: "bit'(#{value})") }
            .to raise_elaboration_error "the given expression should be an integral value: #{type}"
          expect { elaborate(constant_expression: "longint'(#{value})") }
            .to raise_elaboration_error "the given expression should be an integral value: #{type}"
        end
      end
    end
  end

  context 'when a bit width based cast operation is given' do
    it 'should padd or truncate the given expression to the specified bit width' do
      expect(elaborate(constant_expression: "8'(4'ha)"))
        .to match_number(0xA, width: 8)
      expect(elaborate(constant_expression: "8'(0xa)"))
        .to match_number(0xA, width: 8)
      expect(elaborate(constant_expression: "8'(16'habcd)"))
        .to match_number(0xCD, width: 8)
      expect(elaborate(constant_expression: "8'(0xabcd)"))
        .to match_number(0xCD, width: 8)
      expect(elaborate(constant_expression: "8'(true)"))
        .to match_number(1, width: 8)
      expect(elaborate(constant_expression: "8'(false)"))
        .to match_number(0, width: 8)
      expect(elaborate(constant_expression: "true'(2'b11)"))
        .to match_number(1, width: 1)
      expect(elaborate(constant_expression: "2'(4'(8'(16'habcd)))"))
        .to match_number(0b01, width: 2)
    end

    context 'and the specified bit width is 0' do
      it 'should raise ElaborationError' do
        expect { elaborate(constant_expression: "0'(0xa)") }
          .to raise_elaboration_error 'the specified bit width should not be 0'
        expect { elaborate(constant_expression: "false'(0xa)") }
          .to raise_elaboration_error 'the specified bit width should not be 0'
      end
    end

    context 'and the specified bit width is not an integral value' do
      it 'should raise ElaborationError' do
        {
          string: '"this is a string"',
          accesstype: 'na', addressingtype: 'compact', onreadtype: 'rclr', onwritetype: 'woset'
        }.each do |type, value|
          expect { elaborate(constant_expression: "#{value}'(0)") }
            .to raise_elaboration_error "the specified bit width should be an integral value: #{type}"
        end
      end
    end

    context 'and the given expression is not an integral value' do
      it 'should raise ElaborationError' do
        {
          string: '"this is a string"',
          accesstype: 'na', addressingtype: 'compact', onreadtype: 'rclr', onwritetype: 'woset'
        }.each do |type, value|
          expect { elaborate(constant_expression: "4'(#{value})") }
            .to raise_elaboration_error "the given expression should be an integral value: #{type}"
        end
      end
    end
  end
end
