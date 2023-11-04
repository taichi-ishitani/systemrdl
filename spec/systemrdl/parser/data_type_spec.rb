# frozen_string_literal: true

RSpec.describe SystemRDL::Parser, :parser do
  describe 'simple type' do
    let(:parser) do
      SystemRDL::Parser.new(:simple_type)
    end

    specify 'bit, longint and boolean types should parsed by :simple_type parser' do
      expect(parser).to parse('bit').as(data_type(:bit))
      expect(parser).to parse('longint').as(data_type(:longint))
      expect(parser).to parse('boolean').as(data_type(:boolean))
    end
  end

  describe 'basic data type' do
    let(:parser) do
      SystemRDL::Parser.new(:basic_data_type)
    end

    specify 'bit, longint and boolean types should parsed by :basic_data_type parser' do
      expect(parser).to parse('bit').as(data_type(:bit))
      expect(parser).to parse('longint').as(data_type(:longint))
      expect(parser).to parse('boolean').as(data_type(:boolean))
    end

    specify 'bit unsigned, longint unsigned and string types should be parsed by :basic_data_type parser' do
      expect(parser).to parse('bit unsigned').as(data_type(:bit))
      expect(parser).to parse('longint unsigned').as(data_type(:longint))
      expect(parser).to parse('string').as(data_type(:string))
    end

    specify 'user defined types should be parsed by :basic_data_type parser' do
      type = '_'
      expect(parser).to parse(type).as(data_type(type))

      type = 'my_identifier'
      expect(parser).to parse(type).as(data_type(type))

      type = 'My_IdEnTiFiEr'
      expect(parser).to parse(type).as(data_type(type))

      type = 'x'
      expect(parser).to parse(type).as(data_type(type))

      type = '_y0123'
      expect(parser).to parse(type).as(data_type(type))

      type = '_3'
      expect(parser).to parse(type).as(data_type(type))
    end
  end

  describe 'data type' do
    let(:parser) do
      SystemRDL::Parser.new(:data_type)
    end

    specify 'bit, longint and boolean types should parsed by :data_type parser' do
      expect(parser).to parse('bit').as(data_type(:bit))
      expect(parser).to parse('longint').as(data_type(:longint))
      expect(parser).to parse('boolean').as(data_type(:boolean))
    end

    specify 'bit unsigned, longint unsigned and string types should be parsed by :data_type parser' do
      expect(parser).to parse('bit unsigned').as(data_type(:bit))
      expect(parser).to parse('longint unsigned').as(data_type(:longint))
      expect(parser).to parse('string').as(data_type(:string))
    end

    specify 'accesstype, addressingtype, onreadtype and onwritetype types should be parsed by :data_type parser' do
      expect(parser).to parse('accesstype').as(data_type(:accesstype))
      expect(parser).to parse('addressingtype').as(data_type(:addressingtype))
      expect(parser).to parse('onreadtype').as(data_type(:onreadtype))
      expect(parser).to parse('onwritetype').as(data_type(:onwritetype))
    end

    specify 'user defined types should be parsed by :data_type parser' do
      type = '_'
      expect(parser).to parse(type).as(data_type(type))

      type = 'my_identifier'
      expect(parser).to parse(type).as(data_type(type))

      type = 'My_IdEnTiFiEr'
      expect(parser).to parse(type).as(data_type(type))

      type = 'x'
      expect(parser).to parse(type).as(data_type(type))

      type = '_y0123'
      expect(parser).to parse(type).as(data_type(type))

      type = '_3'
      expect(parser).to parse(type).as(data_type(type))
    end
  end
end
