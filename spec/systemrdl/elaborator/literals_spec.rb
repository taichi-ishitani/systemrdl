# frozen_string_literal: true

RSpec.describe SystemRDL::Elaborator, :elaborator do
  context 'when a boolean literal is givne' do
    it 'should elaborate a boolean value' do
      expect(elaborate(boolean_literal: 'true'))
        .to match_value(true, data_type: :boolean)
      expect(elaborate(boolean_literal: 'false'))
        .to match_value(false, data_type: :boolean)
    end
  end

  context 'when a number literal is given' do
    it 'should be elaborate a number value' do
      expect(elaborate(number_literal: '0')).to match_number(0)
      expect(elaborate(number_literal: '0x45')).to match_number(0x45)
      expect(elaborate(number_literal: '4\'d1')).to match_number(1, width: 4)
      expect(elaborate(number_literal: '3\'b101')).to match_number(0b101, width: 3)
      expect(elaborate(number_literal: '32\'hdeadbeaf')).to match_number(0xdeadbeaf, width: 32)
    end

    context 'and the value of a Verilog-style number does not fit within the specified bit-width' do
      it 'should raise ElaborationError' do
        expect {
          elaborate(number_literal: '1\'b10')
        }.to raise_elaboration_error 'value of number does not fit within the specified bit width: 1\'b10'

        expect {
          elaborate(number_literal: '1\'d2')
        }.to raise_elaboration_error 'value of number does not fit within the specified bit width: 1\'d2'

        expect {
          elaborate(number_literal: '31\'hdeadbeaf')
        }.to raise_elaboration_error 'value of number does not fit within the specified bit width: 31\'hdeadbeaf'
      end
    end
  end

  context 'when a sring literal is given' do
    it 'should be elaborate a string value' do
      s = 'This is a string'
      expect(elaborate(string_literal: "\"#{s}\""))
        .to match_value(s, data_type: :string)
    end
  end

  context 'when an accesstype literal is given' do
    it 'should be elaborate an accesstype value' do
      expect(elaborate(accesstype_literal: 'na'))
        .to match_value(be_na_type, data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'rw'))
        .to match_value((be_rw_type.and be_wr_type), data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'wr'))
        .to match_value((be_rw_type.and be_wr_type), data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'r'))
        .to match_value(be_r_type, data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'w'))
        .to match_value(be_w_type, data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'rw1'))
        .to match_value(be_rw1_type, data_type: :accesstype)
      expect(elaborate(accesstype_literal: 'w1'))
        .to match_value(be_w1_type, data_type: :accesstype)
    end
  end

  context 'when an onreadtype literal is given' do
    it 'should elaborate onreadtype value' do
      expect(elaborate(onreadtype_literal: 'rclr'))
        .to match_value(be_rclr_type, data_type: :onreadtype)
      expect(elaborate(onreadtype_literal: 'rset'))
        .to match_value(be_rset_type, data_type: :onreadtype)
      expect(elaborate(onreadtype_literal: 'ruser'))
        .to match_value(be_ruser_type, data_type: :onreadtype)
    end
  end

  context 'when an onwritetype literal is given' do
    it 'should elaborate onwritetype value' do
      expect(elaborate(onwritetype_literal: 'woset'))
        .to match_value(be_woset_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'woclr'))
        .to match_value(be_woclr_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wot'))
        .to match_value(be_wot_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wzs'))
        .to match_value(be_wzs_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wzc'))
        .to match_value(be_wzc_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wzt'))
        .to match_value(be_wzt_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wclr'))
        .to match_value(be_wclr_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wset'))
        .to match_value(be_wset_type, data_type: :onwritetype)
      expect(elaborate(onwritetype_literal: 'wuser'))
        .to match_value(be_wuser_type, data_type: :onwritetype)
    end
  end

  context 'when an addressingtype literal is given' do
    it 'should elaborate an addressingtype value' do
      expect(elaborate(addressingtype_literal: 'compact'))
        .to match_value(be_compact_type, data_type: :addressingtype)
      expect(elaborate(addressingtype_literal: 'regalign'))
        .to match_value(be_regalign_type, data_type: :addressingtype)
      expect(elaborate(addressingtype_literal: 'fullalign'))
        .to match_value(be_fullalign_type, data_type: :addressingtype)
    end
  end

  context 'when a precedencetype literal is given' do
    it 'should elaborate a precedencetype value' do
      expect(elaborate(precedencetype_literal: 'hw'))
        .to match_value(be_hw_type, data_type: :precedencetype)
      expect(elaborate(precedencetype_literal: 'sw'))
        .to match_value(be_sw_type, data_type: :precedencetype)
    end
  end
end
