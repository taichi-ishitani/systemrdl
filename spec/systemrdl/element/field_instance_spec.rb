# frozen_string_literal: true

RSpec.describe SystemRDL::Element::FieldInstance do
  let(:root) do
    SystemRDL::Element::RootInstance.new(:root)
  end

  let(:field) do
    described_class.new(root, nil, :foo, nil)
  end

  describe 'properties' do
    it 'should have general component properties' do
      expect(field).to have_property(:name, type: :string, dynamic_assign: true, value: '')
      expect(field).to have_property(:desc, type: :string, dynamic_assign: true, value: '')
      expect(field).to have_property(:donttest, type: [:boolean, :bit], dynamic_assign: true, value: false)
      expect(field).to have_property(:dontcompare, type: [:boolean, :bit], dynamic_assign: true, value: false)
    end

    it 'should have the content deprecation property' do
      expect(field).to have_property(:ispresent, type: :boolean, dynamic_assign: true, value: true)
    end

    it 'should have field specific properties' do
      # 9.4 Field access properties
      expect(field).to have_property(:hw, type: :accesstype, dynamic_assign: false, value: :rw)
      expect(field).to have_property(:sw, type: :accesstype, dynamic_assign: true, value: :rw)

      # 9.5 Hardware signal properties
      expect(field).to have_property(:next, type: :reference, dynamic_assign: true, ref_target: true)
      expect(field).to have_property(:reset, type: [:bit, :reference], dynamic_assign: true, ref_target: true)
      expect(field).to have_property(:resetsignal, type: :reference, dynamic_assign: true, ref_target: true)

      # 9.6 Software access properties
      expect(field).to have_property(:rclr, type: :boolean, dynamic_assign: true, value: false)
      expect(field).to have_property(:rset, type: :boolean, dynamic_assign: true, value: false)
      expect(field).to have_property(:onread, type: :onreadtype, dynamic_assign: true)
      expect(field).to have_property(:woset, type: :boolean, dynamic_assign: true, value: false)
      expect(field).to have_property(:woclr, type: :boolean, dynamic_assign: true, value: false)
      expect(field).to have_property(:onwrite, type: :onwritetype, dynamic_assign: true)
      expect(field).to have_property(:swwe, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:swwel, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:swmod, type: :boolean, dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:swacc, type: :boolean, dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:singlepulse, type: :boolean, dynamic_assign: true, value: false)

      # 9.7 Hardware access properties
      expect(field).to have_property(:we, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:wel, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:anded, type: :boolean, dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:ored, type: :boolean, dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:xored, type: :boolean, dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:fieldwidth, type: :longint, dynamic_assign: false)
      expect(field).to have_property(:hwclr, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:hwset, type: [:boolean, :reference], dynamic_assign: true, ref_target: true, value: false)
      expect(field).to have_property(:hwenable, type: :reference, dynamic_assign: true, ref_target: true)
      expect(field).to have_property(:hwmask, type: :reference, dynamic_assign: true, ref_target: true)

      # 9.10 Miscellaneous field properties
      expect(field).to have_property(:precedence, type: :precedencetype, dynamic_assign: true, value: :sw)
      expect(field).to have_property(:paritycheck, type: :boolean, dynamic_assign: false, value: false)
    end
  end
end
