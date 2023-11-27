# frozen_string_literal: true

RSpec.describe SystemRDL::Element::RegInstance do
  let(:root) do
    SystemRDL::Element::RootInstance.new(:root)
  end

  let(:reg) do
    described_class.new(root, nil, :foo, nil)
  end

  describe 'properties' do
    it 'should have general component properties' do
      expect(reg).to have_property(:name, type: :string, dynamic_assign: true, value: '')
      expect(reg).to have_property(:desc, type: :string, dynamic_assign: true, value: '')
      expect(reg).to have_property(:donttest, type: :boolean, dynamic_assign: true, value: false)
      expect(reg).to have_property(:dontcompare, type: :boolean, dynamic_assign: true, value: false)
    end

    it 'should have the content deprecation property' do
      expect(reg).to have_property(:ispresent, type: :boolean, dynamic_assign: true, value: true)
    end

    it 'should have reg specific properties' do
      # 10.6 Register properties
      expect(reg).to have_property(:regwidth, type: :longint, dynamic_assign: false)
      expect(reg).to have_property(:accesswidth, type: :longint, dynamic_assign: true)
      expect(reg).to have_property(:errextbus, type: :boolean, dynamic_assign: false, value: false)
      expect(reg).to have_property(:shared, type: :boolean, dynamic_assign: false, value: false)
    end
  end
end
