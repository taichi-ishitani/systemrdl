# frozen_string_literal: true

RSpec.describe SystemRDL::Elaborator, :elaborator do
  context 'when a property assignment is given' do
    let(:foo_component) do
      create_component(nil, :foo) do |addrmap|
        3.times do |i|
          create_component(addrmap, :bar, [i]) do |reg|
            create_component(reg, :baz)
          end
        end
      end
    end

    let(:bar_components) do
      foo_component.components
    end

    let(:baz_components) do
      bar_components.flat_map(&:components)
    end

    it 'should evaluate the given assignment and update the property' do
      property = create_proparty(foo_component, :desc, :string, false, true)
      expect { elaborate(context: foo_component, property_assignment: 'desc = "foo component";') }
        .to change(property, :value).from(be_nil).to('foo component')

      property = create_proparty(baz_components[0], :desc, :string, false, true)
      expect { elaborate(context: bar_components[0], property_assignment: 'baz->desc = "baz component";') }
        .to change(property, :value).from(be_nil).to('baz component')

      properties = bar_components.map do |component|
        create_proparty(component, :name, :string, false, true)
      end
      expect { elaborate(context: foo_component, property_assignment: 'bar[0]->name = "bar[0] component";') }
        .to change(properties[0], :value).to('bar[0] component')
        .and not_change(properties[1], :value)
        .and not_change(properties[2], :value)

      properties = baz_components.map do |component|
        create_proparty(component, :name, :string, false, true)
      end
      expect { elaborate(context: foo_component, property_assignment: 'bar.baz->name = "baz component";') }
        .to change(properties[0], :value).from(be_nil).to('baz component')
        .and change(properties[1], :value).from(be_nil).to('baz component')
        .and change(properties[2], :value).from(be_nil).to('baz component')

      property = create_proparty(baz_components[0], :next, :reference, true, true)
      expect { elaborate(context: foo_component, property_assignment: 'bar[0].baz->next = bar[1].baz;') }
        .to change(property, :value).from(be_nil).to(be(baz_components[1]))

      property = create_proparty(baz_components[1], :swwe, [:boolean, :reference], true, true)
      expect { elaborate(context: foo_component, property_assignment: 'bar[1].baz->swwe = true;') }
        .to change(property, :value).from(be_nil).to(true)

      ored = create_proparty(baz_components[0], :ored, :boolean, true, true)
      property = create_proparty(baz_components[2], :swwe, [:boolean, :reference], true, true)
      expect { elaborate(context: foo_component, property_assignment: 'bar[2].baz->swwe = bar[0].baz->ored;') }
        .to change(property, :value).from(be_nil).to(be(ored))

      property = create_proparty(baz_components[0], :rclr, :boolean, false, true)
      expect { elaborate(context: baz_components[0], property_assignment: 'rclr;') }
        .to change(property, :value).from(be_nil).to(true)

      property = create_proparty(baz_components[1], :rclr, :boolean, false, true)
      expect { elaborate(context: bar_components[1], property_assignment: 'baz->rclr;') }
        .to change(property, :value).from(be_nil).to(true)
    end

    context 'and the given LHS does not support dynamic assignment' do
      it 'should raise ElaborationError' do
        create_proparty(baz_components[0], :sw, :accesstype, false, true)
        expect { elaborate(context: bar_components[0], property_assignment: 'baz->sw = rw;') }
          .not_to raise_error

        create_proparty(baz_components[0], :hw, :accesstype, false, false)
        expect { elaborate(context: bar_components[0], property_assignment: 'baz->hw = rw;') }
          .to raise_elaboration_error 'the given LHS does not support dynamic assignment'
      end
    end

    context 'and the type of the given LHS is non-boolean type and no RSH value is given' do
      it 'should raise ElaborationError' do
        create_proparty(baz_components[0], :name, :string, false, true)
        expect { elaborate(context: baz_components[0], property_assignment: 'name;') }
          .to raise_elaboration_error 'no RHS is given'

        create_proparty(baz_components[1], :name, :string, false, true)
        expect { elaborate(context: bar_components[1], property_assignment: 'baz->name;') }
          .to raise_elaboration_error 'no RHS is given'
      end
    end

    context 'and the given LHS and RHS are incompatible' do
      it 'should raise ElaborationError' do
        create_proparty(baz_components[0], :name, :string, false, true)
        create_proparty(baz_components[1], :next, :reference, true, true)
        expect { elaborate(context: baz_components[0], property_assignment: 'name = true;') }
          .to raise_elaboration_error 'the given LHS and RHS are incompatible'
        expect { elaborate(context: foo_component, property_assignment: 'bar[0].baz->name = bar[1].baz;') }
          .to raise_elaboration_error 'the given LHS and RHS are incompatible'
        expect { elaborate(context: foo_component, property_assignment: 'bar[1].baz->next = bar[0].baz->name;') }
          .to raise_elaboration_error 'the given LHS and RHS are incompatible'
        expect { elaborate(context: foo_component, property_assignment: 'bar[1].baz->next = true;') }
          .to raise_elaboration_error 'the given LHS and RHS are incompatible'
      end
    end

    context 'the given assignment is second time assignment at scope' do
      it 'should raise ElaborationError' do
        baz_components.each do |baz_component|
          create_proparty(baz_component, :name, :string, false, true)
        end

        elaborate(context: baz_components[0], property_assignment: 'name = "baz";')
        expect { elaborate(context: baz_components[0], property_assignment: 'name = "baz";') }
          .to raise_elaboration_error 'no more than one assignment per scope is allowed'

        elaborate(context: bar_components[0], property_assignment: 'baz->name = "baz";')
        expect { elaborate(context: bar_components[0], property_assignment: 'baz->name = "baz";') }
          .to raise_elaboration_error 'no more than one assignment per scope is allowed'

        elaborate(context: foo_component, property_assignment: 'bar[0].baz->name = "baz";')
        expect { elaborate(context: foo_component, property_assignment: 'bar[0].baz->name = "baz";') }
          .to raise_elaboration_error 'no more than one assignment per scope is allowed'
        expect { elaborate(context: foo_component, property_assignment: 'bar.baz->name = "baz";') }
          .to raise_elaboration_error 'no more than one assignment per scope is allowed'
      end
    end
  end
end
