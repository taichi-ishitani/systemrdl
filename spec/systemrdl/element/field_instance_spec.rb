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
      expect(field).to have_property(:name, type: :string, dynamic_assign: true)
      expect(field).to have_property(:desc, type: :string, dynamic_assign: true)
      expect(field).to have_property(:donttest, type: [:boolean, :bit], dynamic_assign: true)
      expect(field).to have_property(:dontcompare, type: [:boolean, :bit], dynamic_assign: true)
    end

    it 'should have the content deprecation property' do
      expect(field).to have_property(:ispresent, type: :boolean, dynamic_assign: true, value: true)
    end
  end
end
