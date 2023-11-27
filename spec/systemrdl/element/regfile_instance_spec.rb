# frozen_string_literal: true

RSpec.describe SystemRDL::Element::RegfileInstance do
  let(:root) do
    SystemRDL::Element::RootInstance.new(:root)
  end

  let(:regfile) do
    described_class.new(root, nil, :foo, nil)
  end

  describe 'properties' do
    it 'should have general component properties' do
      expect(regfile).to have_property(:name, type: :string, dynamic_assign: true, value: '')
      expect(regfile).to have_property(:desc, type: :string, dynamic_assign: true, value: '')
      expect(regfile).to have_property(:donttest, type: :boolean, dynamic_assign: true, value: false)
      expect(regfile).to have_property(:dontcompare, type: :boolean, dynamic_assign: true, value: false)
    end

    it 'should have the content deprecation property' do
      expect(regfile).to have_property(:ispresent, type: :boolean, dynamic_assign: true, value: true)
    end

    it 'should have regfile specific properties' do
      # 12.3 Register file properties
      expect(regfile).to have_property(:alignment, type: :longint, dynamic_assign: false)
      expect(regfile).to have_property(:sharedextbus, type: :boolean, dynamic_assign: false, value: false)
      expect(regfile).to have_property(:errextbus, type: :boolean, dynamic_assign: false, value: false)
    end
  end
end
