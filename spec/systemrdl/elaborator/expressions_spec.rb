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

  context 'when an unary operation is given' do
    it 'should evaluate the given operation' do
      ['true', "2'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "!#{value}")).to match_value(false, data_type: :boolean)
      end

      ['false', "2'd0", '0'].each do |value|
        expect(elaborate(constant_expression: "!#{value}")).to match_value(true, data_type: :boolean)
      end

      [['true', [1, 1, 0]], ['false', [0, 0, 1]], ["1'd1", [1, 1, 0]], ["1'd0", [0, 0, 1]]].each do |input, result|
        expect(elaborate(constant_expression: "+#{input}")).to match_number(result[0], width: 1)
        expect(elaborate(constant_expression: "-#{input}")).to match_number(result[1], width: 1)
        expect(elaborate(constant_expression: "~#{input}")).to match_number(result[2], width: 1)
      end

      [["2'd0", [0, 0, 3]], ["2'd1", [1, 3, 2]], ["2'd2", [2, 2, 1]], ["2'd3", [3, 1, 0]]].each do |input, result|
        expect(elaborate(constant_expression: "+#{input}")).to match_number(result[0], width: 2)
        expect(elaborate(constant_expression: "-#{input}")).to match_number(result[1], width: 2)
        expect(elaborate(constant_expression: "~#{input}")).to match_number(result[2], width: 2)
      end

      [
        ['0x0000_0000_0000_0000', [0x0000_0000_0000_0000, 0x0000_0000_0000_0000, 0xFFFF_FFFF_FFFF_FFFF]],
        ['0x0000_0000_0000_0001', [0x0000_0000_0000_0001, 0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFE]],
        ['0x0000_0000_0000_0002', [0x0000_0000_0000_0002, 0xFFFF_FFFF_FFFF_FFFE, 0xFFFF_FFFF_FFFF_FFFD]],
        ['0x8000_0000_0000_0000', [0x8000_0000_0000_0000, 0x8000_0000_0000_0000, 0x7FFF_FFFF_FFFF_FFFF]],
        ['0xFFFF_FFFF_FFFF_FFFE', [0xFFFF_FFFF_FFFF_FFFE, 0x0000_0000_0000_0002, 0x0000_0000_0000_0001]],
        ['0xFFFF_FFFF_FFFF_FFFF', [0xFFFF_FFFF_FFFF_FFFF, 0x0000_0000_0000_0001, 0x0000_0000_0000_0000]]
      ].each do |input, result|
        expect(elaborate(constant_expression: "+#{input}")).to match_number(result[0])
        expect(elaborate(constant_expression: "-#{input}")).to match_number(result[1])
        expect(elaborate(constant_expression: "~#{input}")).to match_number(result[2])
      end

      [
        ['true' , [1, 0, 1, 0, 1, 0, 0]],
        ['false', [0, 1, 0, 1, 0, 1, 1]],
        ["1'd1" , [1, 0, 1, 0, 1, 0, 0]],
        ["1'd0" , [0, 1, 0, 1, 0, 1, 1]]
      ].each do |input, result|
        expect(elaborate(constant_expression: "&#{input}")).to match_number(result[0], width: 1)
        expect(elaborate(constant_expression: "~&#{input}")).to match_number(result[1], width: 1)
        expect(elaborate(constant_expression: "|#{input}")).to match_number(result[2], width: 1)
        expect(elaborate(constant_expression: "~|#{input}")).to match_number(result[3], width: 1)
        expect(elaborate(constant_expression: "^#{input}")).to match_number(result[4], width: 1)
        expect(elaborate(constant_expression: "~^#{input}")).to match_number(result[5], width: 1)
        expect(elaborate(constant_expression: "^~#{input}")).to match_number(result[6], width: 1)
      end

      [
        ["2'd0", [0, 1, 0, 1, 0, 1, 1]],
        ["2'd1", [0, 1, 1, 0, 1, 0, 0]],
        ["2'd2", [0, 1, 1, 0, 1, 0, 0]],
        ["2'd3", [1, 0, 1, 0, 0, 1, 1]]
      ].each do |input, result|
        expect(elaborate(constant_expression: "&#{input}")).to match_number(result[0], width: 1)
        expect(elaborate(constant_expression: "~&#{input}")).to match_number(result[1], width: 1)
        expect(elaborate(constant_expression: "|#{input}")).to match_number(result[2], width: 1)
        expect(elaborate(constant_expression: "~|#{input}")).to match_number(result[3], width: 1)
        expect(elaborate(constant_expression: "^#{input}")).to match_number(result[4], width: 1)
        expect(elaborate(constant_expression: "~^#{input}")).to match_number(result[5], width: 1)
        expect(elaborate(constant_expression: "^~#{input}")).to match_number(result[6], width: 1)
      end

      [
        ['0x0000_0000_0000_0000', [0, 1, 0, 1, 0, 1, 1]],
        ['0x0000_0000_0000_0001', [0, 1, 1, 0, 1, 0, 0]],
        ['0x0000_0000_0000_0002', [0, 1, 1, 0, 1, 0, 0]],
        ['0x8000_0000_0000_0000', [0, 1, 1, 0, 1, 0, 0]],
        ['0xFFFF_FFFF_FFFF_FFFE', [0, 1, 1, 0, 1, 0, 0]],
        ['0xFFFF_FFFF_FFFF_FFFF', [1, 0, 1, 0, 0, 1, 1]]
      ].each do |input, result|
        expect(elaborate(constant_expression: "&#{input}")).to match_number(result[0], width: 1)
        expect(elaborate(constant_expression: "~&#{input}")).to match_number(result[1], width: 1)
        expect(elaborate(constant_expression: "|#{input}")).to match_number(result[2], width: 1)
        expect(elaborate(constant_expression: "~|#{input}")).to match_number(result[3], width: 1)
        expect(elaborate(constant_expression: "^#{input}")).to match_number(result[4], width: 1)
        expect(elaborate(constant_expression: "~^#{input}")).to match_number(result[5], width: 1)
        expect(elaborate(constant_expression: "^~#{input}")).to match_number(result[6], width: 1)
      end
    end

    context 'and the given operand is not an integral value' do
      it 'should raise ElaborationError' do
        {
          string: '"this is a string"',
          accesstype: 'na', addressingtype: 'compact', onreadtype: 'rclr', onwritetype: 'woset'
        }.each do |type, value|
          ['!', '+', '-', '~', '&', '~&', '|', '~|', '^', '~^', '^~'].each do |operator|
            expect { elaborate(constant_expression: "#{operator}#{value}") }
              .to raise_elaboration_error "the given operand should be an integral value: #{type}"
          end
        end
      end
    end
  end

  context 'when a binary operation is given' do
    it 'should evaluate the given operation' do
      ['true', '1', "1'b1"].product(['true', '1', "1'b1"]).each do |values|
        expect(elaborate(constant_expression: "#{values[0]} && #{values[1]}"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', '0', "1'b0"].product(['false', '0', "1'b0", 'true', '1', "1'b1"]).each do |values|
        expect(elaborate(constant_expression: "#{values[0]} && #{values[1]}"))
          .to match_value(false, data_type: :boolean)
      end

      ['false', '0', "1'b0"].product(['false', '0', "1'b0"]).each do |values|
        expect(elaborate(constant_expression: "#{values[0]} || #{values[1]}"))
          .to match_value(false, data_type: :boolean)
      end

      ['true', '1', "1'b1"].product(['false', '0', "1'b0", 'true', '1', "1'b1"]).each do |values|
        expect(elaborate(constant_expression: "#{values[0]} || #{values[1]}"))
          .to match_value(true, data_type: :boolean)
      end

      ['true', "1'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "1'd0 < #{value}"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "0 < #{value}"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', "1'd0", '0'].each do |value|
        expect(elaborate(constant_expression: "1'd0 < #{value}"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "0 < #{value}"))
          .to match_value(false, data_type: :boolean)
      end

      ['true', "1'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "#{value} > 1'd0"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} > 0"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', "1'd0", '0'].each do |value|
        expect(elaborate(constant_expression: "#{value} > 1'd0"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} > 0"))
          .to match_value(false, data_type: :boolean)
      end

      ['true', "1'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "1'd1 <= #{value}"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "1 <= #{value}"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', "1'd0", '0'].each do |value|
        expect(elaborate(constant_expression: "1'd1 <= #{value}"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "1 <= #{value}"))
          .to match_value(false, data_type: :boolean)
      end

      ['true', "1'd1", "2'd2", '1', '2'].each do |value|
        expect(elaborate(constant_expression: "#{value} >= 1'd1"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} >= 1"))
          .to match_value(true, data_type: :boolean)
      end

      ['false', "1'd0", '0'].each do |value|
        expect(elaborate(constant_expression: "#{value} >= 1'd1"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} >= 1"))
          .to match_value(false, data_type: :boolean)
      end

      ['true', "1'd1", '1'].each do |value|
        expect(elaborate(constant_expression: "#{value} == 1'd1"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} == 1"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} == true"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != 1'd1"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != 1"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != true"))
          .to match_value(false, data_type: :boolean)
      end

      ['false', "1'd0", '0', "2'd2", '2'].each do |value|
        expect(elaborate(constant_expression: "#{value} == 1'd1"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} == 1"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} == true"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != 1'd1"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != 1"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{value} != true"))
          .to match_value(true, data_type: :boolean)
      end

      [
        ['na'     , ['na'     , 'rw'      ]],
        ['rclr'   , ['rclr'   , 'rset'    ]],
        ['woset'  , ['woset'  , 'woclr'   ]],
        ['compact', ['compact', 'regalign']],
        ['"foo"'  , ['"foo"'  , '"bar"'   ]]
      ].each do |l_op, r_op|
        expect(elaborate(constant_expression: "#{l_op} == #{r_op[0]}"))
          .to match_value(true, data_type: :boolean)
        expect(elaborate(constant_expression: "#{l_op} != #{r_op[0]}"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{l_op} == #{r_op[1]}"))
          .to match_value(false, data_type: :boolean)
        expect(elaborate(constant_expression: "#{l_op} != #{r_op[1]}"))
          .to match_value(true, data_type: :boolean)
      end

      [
        ["3'd1", "65'd0", 1,  3],
        ["3'd1", "65'd1", 2,  3],
        ["3'd1", "65'd2", 4,  3],
        ["3'd1", "65'd3", 0,  3],
        ['1'   , "65'd0", 1, 64],
        ['1'   , "65'd1", 2, 64],
        ['1'   , "65'd2", 4, 64],
        ['1'   , "65'd3", 8, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} << #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["3'd4", "65'd0", 4,  3],
        ["3'd4", "65'd1", 2,  3],
        ["3'd4", "65'd2", 1,  3],
        ["3'd4", "65'd3", 0,  3],
        ['4'   , "65'd0", 4, 64],
        ['4'   , "65'd1", 2, 64],
        ['4'   , "65'd2", 1, 64],
        ['4'   , "65'd3", 0, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} >> #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["1'd0" , [0, 1, 3, 0                    , 0xFFFF_FFFF_FFFF_FFFC],  2],
        ["1'd1" , [1, 1, 2, 1                    , 0xFFFF_FFFF_FFFF_FFFD],  2],
        ["2'd2" , [2, 3, 1, 2                    , 0xFFFF_FFFF_FFFF_FFFE],  2],
        ["2'd3" , [3, 3, 0, 3                    , 0xFFFF_FFFF_FFFF_FFFF],  2],
        ["3'd4" , [0, 5, 7, 0                    , 0xFFFF_FFFF_FFFF_FFF8],  3],
        ["3'd5" , [1, 5, 6, 1                    , 0xFFFF_FFFF_FFFF_FFF9],  3],
        ["3'd6" , [2, 7, 5, 2                    , 0xFFFF_FFFF_FFFF_FFFA],  3],
        ["3'd7" , [3, 7, 4, 3                    , 0xFFFF_FFFF_FFFF_FFFB],  3],
        ['0'    , [0, 1, 3, 0xFFFF_FFFF_FFFF_FFFC, 0xFFFF_FFFF_FFFF_FFFC], 64],
        ['1'    , [1, 1, 2, 0xFFFF_FFFF_FFFF_FFFD, 0xFFFF_FFFF_FFFF_FFFD], 64],
        ['2'    , [2, 3, 1, 0xFFFF_FFFF_FFFF_FFFE, 0xFFFF_FFFF_FFFF_FFFE], 64],
        ['3'    , [3, 3, 0, 0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF], 64],
        ['4'    , [0, 5, 7, 0xFFFF_FFFF_FFFF_FFF8, 0xFFFF_FFFF_FFFF_FFF8], 64],
        ['5'    , [1, 5, 6, 0xFFFF_FFFF_FFFF_FFF9, 0xFFFF_FFFF_FFFF_FFF9], 64],
        ['6'    , [2, 7, 5, 0xFFFF_FFFF_FFFF_FFFA, 0xFFFF_FFFF_FFFF_FFFA], 64],
        ['7'    , [3, 7, 4, 0xFFFF_FFFF_FFFF_FFFB, 0xFFFF_FFFF_FFFF_FFFB], 64],
        ['false', [0, 1, 3, 0                    , 0xFFFF_FFFF_FFFF_FFFC],  2],
        ['true' , [1, 1, 2, 1                    , 0xFFFF_FFFF_FFFF_FFFD],  2]
      ].each do |input, results, width|
        expect(elaborate(constant_expression: "2'd3 & #{input}"))
          .to match_number(results[0], width: width)
        expect(elaborate(constant_expression: "3 & #{input}"))
          .to match_number(results[0])
        expect(elaborate(constant_expression: "2'd1 | #{input}"))
          .to match_number(results[1], width: width)
        expect(elaborate(constant_expression: "1 | #{input}"))
          .to match_number(results[1])
        expect(elaborate(constant_expression: "2'd3 ^ #{input}"))
          .to match_number(results[2], width: width)
        expect(elaborate(constant_expression: "3 ^ #{input}"))
          .to match_number(results[2])
        expect(elaborate(constant_expression: "2'd3 ~^ #{input}"))
          .to match_number(results[3], width: width)
        expect(elaborate(constant_expression: "3 ~^ #{input}"))
          .to match_number(results[4])
        expect(elaborate(constant_expression: "2'd3 ^~ #{input}"))
          .to match_number(results[3], width: width)
        expect(elaborate(constant_expression: "3 ^~ #{input}"))
          .to match_number(results[4])
      end

      [
        ["8'd128", "1'd0",   0,  8],
        ["8'd128", "1'd1", 128,  8],
        ["8'd128", "2'd2",   0,  8],
        ['128'   , "1'd0",   0, 64],
        ['128'   , "1'd1", 128, 64],
        ['128'   , "2'd2", 256, 64],
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} * #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["3'd6", "2'd3", 2,  3],
        ["3'd5", "2'd3", 1,  3],
        ["3'd4", "2'd3", 1,  3],
        ["2'd3", "2'd3", 1,  2],
        ["2'd2", "2'd3", 0,  2],
        ["1'd1", "2'd3", 0,  2],
        ["1'd0", "2'd3", 0,  2],
        ['6'   , "2'd3", 2, 64],
        ['5'   , "2'd3", 1, 64],
        ['4'   , "2'd3", 1, 64],
        ['3'   , "2'd3", 1, 64],
        ['2'   , "2'd3", 0, 64],
        ['1'   , "2'd3", 0, 64],
        ['0'   , "2'd3", 0, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} / #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["3'd6", "2'd3", 0,  3],
        ["3'd5", "2'd3", 2,  3],
        ["3'd4", "2'd3", 1,  3],
        ["2'd3", "2'd3", 0,  2],
        ["2'd2", "2'd3", 2,  2],
        ["1'd1", "2'd3", 1,  2],
        ["1'd0", "2'd3", 0,  2],
        ['6'   , "2'd3", 0, 64],
        ['5'   , "2'd3", 2, 64],
        ['4'   , "2'd3", 1, 64],
        ['3'   , "2'd3", 0, 64],
        ['2'   , "2'd3", 2, 64],
        ['1'   , "2'd3", 1, 64],
        ['0'   , "2'd3", 0, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} % #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["8'd254", "1'd0", 254,  8],
        ["8'd254", "1'd1", 255,  8],
        ["8'd254", "2'd2",   0,  8],
        ['254'   , "1'd0", 254, 64],
        ['254'   , "1'd1", 255, 64],
        ['254'   , "2'd2", 256, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} + #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["8'd1", "1'd0", 1                    ,  8],
        ["8'd1", "1'd1", 0                    ,  8],
        ["8'd1", "2'd2", 255                  ,  8],
        ['1'   , "1'd0", 1                    , 64],
        ['1'   , "1'd1", 0                    , 64],
        ['1'   , "2'd2", 0xFFFF_FFFF_FFFF_FFFF, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} - #{op_r}"))
          .to match_number(result, width: width)
      end

      [
        ["6'd4", "65'd0",  1,  6],
        ["6'd4", "65'd1",  4,  6],
        ["6'd4", "65'd2", 16,  6],
        ["6'd4", "65'd3",  0,  6],
        ['4'   , "65'd0",  1, 64],
        ['4'   , "65'd1",  4, 64],
        ['4'   , "65'd2", 16, 64],
        ['4'   , "65'd3", 64, 64]
      ].each do |op_l, op_r, result, width|
        expect(elaborate(constant_expression: "#{op_l} ** #{op_r}"))
          .to match_number(result, width: width)
      end

      expect(elaborate(constant_expression: "(8'hFF + 8'h01) >> 1"))
        .to match_number(0x0, width: 8)
      expect(elaborate(constant_expression: "(0xFF + 0x01) >> 1"))
        .to match_number(0x80)
    end

    context 'and the second operand for the division or modulus operations is zero' do
      it 'should raise ElaborationError' do
        expect {
          elaborate(constant_expression: "1'd1 / 1'd0")
        }.to raise_elaboration_error "the second operand for the / operation should not 0"

        expect {
          elaborate(constant_expression: "1'd1 / 0")
        }.to raise_elaboration_error "the second operand for the / operation should not 0"

        expect {
          elaborate(constant_expression: "1'd1 / false")
        }.to raise_elaboration_error "the second operand for the / operation should not 0"

        expect {
          elaborate(constant_expression: "1'd1 % 1'd0")
        }.to raise_elaboration_error "the second operand for the % operation should not 0"

        expect {
          elaborate(constant_expression: "1'd1 % 0")
        }.to raise_elaboration_error "the second operand for the % operation should not 0"

        expect {
          elaborate(constant_expression: "1'd1 % false")
        }.to raise_elaboration_error "the second operand for the % operation should not 0"
      end
    end

    context 'and the given operand is not an integral value' do
      it 'should raise ElaborationError' do
        {
          string: '"this is a string"',
          accesstype: 'na', addressingtype: 'compact', onreadtype: 'rclr', onwritetype: 'woset'
        }.each do |type, value|
          [
            '&&', '||', '<', '>', '<=', '>=', '>>', '<<',
            '&', '|', '^', '~^', '^~', '*', '/', '%', '+', '-', '**'
          ].each do |operator|
            expect { elaborate(constant_expression: "#{value} #{operator} 1") }
              .to raise_elaboration_error "the given operand should be an integral value: #{type}"

            expect { elaborate(constant_expression: "1 #{operator} #{value}") }
              .to raise_elaboration_error "the given operand should be an integral value: #{type}"
          end
        end
      end
    end
  end
end
