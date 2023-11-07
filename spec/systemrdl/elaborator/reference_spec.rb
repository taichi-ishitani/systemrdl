# frozen_string_literal: true

RSpec.describe SystemRDL::Elaborator, :elaborator do
  context 'when a reference to a local element is given' do
    let(:foo_component) do
      create_component(nil, :foo) do |addrmap|
        3.times do |i|
          create_component(addrmap, :bar, [i]) do |reg|
            create_component(reg, :baz) do |field|
              create_proparty(field, :name, :string)
            end
          end
        end
      end
    end

    let(:bar_component) do
      foo_component.components.first
    end

    let(:bar_components) do
      foo_component.components[0..2]
    end

    let(:baz_component) do
      bar_component.components.first
    end

    let(:baz_components) do
      bar_components.flat_map(&:components)
    end

    let(:baz_property) do
      baz_component.properties.first
    end

    let(:baz_properties) do
      baz_components.flat_map(&:properties)
    end

    it 'should return the specified element' do
      expect(elaborate(context: baz_component, instance_ref: 'name'))
        .to match([be(baz_property)])

      expect(elaborate(context: bar_component, instance_ref: 'baz'))
        .to match([be(baz_component)])
      expect(elaborate(context: bar_component, property_ref: 'baz->name'))
        .to match([be(baz_property)])

      expect(elaborate(context: foo_component, instance_ref: 'bar[0]'))
        .to match([be(bar_component)])
      expect(elaborate(context: foo_component, instance_ref: 'bar'))
        .to match([be(bar_components[0]), be(bar_components[1]), be(bar_components[2])])
      expect(elaborate(context: foo_component, instance_ref: 'bar[0].baz'))
        .to match([be(baz_component)])
      expect(elaborate(context: foo_component, instance_ref: 'bar.baz'))
        .to match([be(baz_components[0]), be(baz_components[1]), be(baz_components[2])])
      expect(elaborate(context: foo_component, property_ref: 'bar[0].baz->name'))
        .to match([be(baz_property)])
      expect(elaborate(context: foo_component, property_ref: 'bar.baz->name'))
        .to match([be(baz_properties[0]), be(baz_properties[1]), be(baz_properties[2])])
    end

    context 'and the given local element is not found' do
      it 'should raise ElaborationError' do
        expect {
          elaborate(context: baz_component, instance_ref: 'foo')
        }.to raise_elaboration_error 'the given reference is not found: foo'

        expect {
          elaborate(context: bar_component, instance_ref: 'foo')
        }.to raise_elaboration_error 'the given reference is not found: foo'
        expect {
          elaborate(context: bar_component, property_ref: 'foo->name')
        }.to raise_elaboration_error 'the given reference is not found: foo->name'
        expect {
          elaborate(context: bar_component, property_ref: 'baz->foo')
        }.to raise_elaboration_error 'the given reference is not found: baz->foo'

        expect {
          elaborate(context: foo_component, instance_ref: 'baz[3]')
        }.to raise_elaboration_error 'the given reference is not found: baz[3]'
        expect {
          elaborate(context: foo_component, instance_ref: 'foo[0]')
        }.to raise_elaboration_error 'the given reference is not found: foo[0]'
        expect {
          elaborate(context: foo_component, instance_ref: 'foo')
        }.to raise_elaboration_error 'the given reference is not found: foo'
        expect {
          elaborate(context: foo_component, instance_ref: 'bar[0].qux')
        }.to raise_elaboration_error 'the given reference is not found: bar[0].qux'
        expect {
          elaborate(context: foo_component, instance_ref: 'bar.qux')
        }.to raise_elaboration_error 'the given reference is not found: bar.qux'
        expect {
          elaborate(context: foo_component, instance_ref: 'bar[3].baz')
        }.to raise_elaboration_error 'the given reference is not found: bar[3].baz'
        expect {
          elaborate(context: foo_component, instance_ref: 'foo[0].baz')
        }.to raise_elaboration_error 'the given reference is not found: foo[0].baz'
        expect {
          elaborate(context: foo_component, instance_ref: 'foo.baz')
        }.to raise_elaboration_error 'the given reference is not found: foo.baz'
        expect {
          elaborate(context: foo_component, property_ref: 'bar[0].qux->name')
        }.to raise_elaboration_error 'the given reference is not found: bar[0].qux->name'
        expect {
          elaborate(context: foo_component, property_ref: 'bar.qux->name')
        }.to raise_elaboration_error 'the given reference is not found: bar.qux->name'
        expect {
          elaborate(context: foo_component, property_ref: 'bar[3].baz->name')
        }.to raise_elaboration_error 'the given reference is not found: bar[3].baz->name'
        expect {
          elaborate(context: foo_component, instance_ref: 'foo[0].baz')
        }.to raise_elaboration_error 'the given reference is not found: foo[0].baz'
        expect {
          elaborate(context: foo_component, property_ref: 'foo.baz->name')
        }.to raise_elaboration_error 'the given reference is not found: foo.baz->name'
        expect {
          elaborate(context: foo_component, property_ref: 'bar[0].baz->qux')
        }.to raise_elaboration_error 'the given reference is not found: bar[0].baz->qux'
        expect {
          elaborate(context: foo_component, property_ref: 'bar.baz->qux')
        }.to raise_elaboration_error 'the given reference is not found: bar.baz->qux'
        expect {
          elaborate(context: foo_component, instance_ref: 'bar[0].baz.qux')
        }.to raise_elaboration_error 'the given reference is not found: bar[0].baz.qux'
        expect {
          elaborate(context: foo_component, instance_ref: 'bar.baz.qux')
        }.to raise_elaboration_error 'the given reference is not found: bar.baz.qux'
      end
    end
  end
end
