# frozen_string_literal: true

RSpec.describe SystemRDL::Element::AddrmapInstance do
  let(:root) do
    SystemRDL::Element::RootInstance.new(:root)
  end

  let(:addrmap) do
    described_class.new(root, nil, :foo, nil)
  end

  describe 'properties' do
    it 'should have general component properties' do
      expect(addrmap).to have_property(:name, type: :string, dynamic_assign: true, value: '')
      expect(addrmap).to have_property(:desc, type: :string, dynamic_assign: true, value: '')
      expect(addrmap).to have_property(:donttest, type: :boolean, dynamic_assign: true, value: false)
      expect(addrmap).to have_property(:dontcompare, type: :boolean, dynamic_assign: true, value: false)
    end

    it 'should have the content deprecation property' do
      expect(addrmap).to have_property(:ispresent, type: :boolean, dynamic_assign: true, value: true)
    end

    it 'should have addrmap specific propertied' do
      # 13.4 Address map properties
      expect(addrmap).to have_property(:alignment, type: :longint, dynamic_assign: false)
      expect(addrmap).to have_property(:sharedextbus, type: :boolean, dynamic_assign: false, value: false)
      expect(addrmap).to have_property(:errextbus, type: :boolean, dynamic_assign: false, value: false)
      expect(addrmap).to have_property(:bigendian, type: :boolean, dynamic_assign: true, value: false)
      expect(addrmap).to have_property(:littleendian, type: :boolean, dynamic_assign: true, value: false)
      expect(addrmap).to have_property(:addressing, type: :addressingtype, dynamic_assign: false, value: :regalign)
      expect(addrmap).to have_property(:rsvdset, type: :boolean, dynamic_assign: false, value: false)
      expect(addrmap).to have_property(:rsvdsetX, type: :boolean, dynamic_assign: false, value: false)
      expect(addrmap).to have_property(:msb0, type: :boolean, dynamic_assign: false, value: false)
      expect(addrmap).to have_property(:lsb0, type: :boolean, dynamic_assign: false, value: false)
    end
  end
end
