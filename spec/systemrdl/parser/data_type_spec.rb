# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  def data_type(m, type = nil)
    proc do |result|
      result.is_a?(SystemRDL::AST::DataType) &&
        result.__send__(m) && (type.nil? || result.data_type == type)
    end
  end

  describe 'simple type' do
    let(:parser) do
      SystemRDL::Parser.new(:simple_type)
    end

    specify 'bit, longint and boolean types should parsed by :simple_type parser' do
      expect(parser).to parse('bit', trace: true).as(&data_type(:bit?))
      expect(parser).to parse('longint', trace: true).as(&data_type(:longint?))
      expect(parser).to parse('boolean', trace: true).as(&data_type(:boolean?))
    end
  end

  describe 'basic data type' do
    let(:parser) do
      SystemRDL::Parser.new(:basic_data_type)
    end

    specify 'bit, longint and boolean types should parsed by :basic_data_type parser' do
      expect(parser).to parse('bit', trace: true).as(&data_type(:bit?))
      expect(parser).to parse('longint', trace: true).as(&data_type(:longint?))
      expect(parser).to parse('boolean', trace: true).as(&data_type(:boolean?))
    end

    specify 'bit unsigned, longint unsigned and string types should be parsed by :basic_data_type parser' do
      expect(parser).to parse('bit unsigned', trace: true).as(&data_type(:bit?))
      expect(parser).to parse('longint unsigned', trace: true).as(&data_type(:longint?))
      expect(parser).to parse('string', trace: true).as(&data_type(:string?))
    end

    specify 'user defined types should be parsed by :basic_data_type parser' do
      type = '_'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'my_identifier'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'My_IdEnTiFiEr'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'x'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = '_y0123'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = '_3'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))
    end
  end

  describe 'data type' do
    let(:parser) do
      SystemRDL::Parser.new(:data_type)
    end

    specify 'bit, longint and boolean types should parsed by :data_type parser' do
      expect(parser).to parse('bit', trace: true).as(&data_type(:bit?))
      expect(parser).to parse('longint', trace: true).as(&data_type(:longint?))
      expect(parser).to parse('boolean', trace: true).as(&data_type(:boolean?))
    end

    specify 'bit unsigned, longint unsigned and string types should be parsed by :data_type parser' do
      expect(parser).to parse('bit unsigned', trace: true).as(&data_type(:bit?))
      expect(parser).to parse('longint unsigned', trace: true).as(&data_type(:longint?))
      expect(parser).to parse('string', trace: true).as(&data_type(:string?))
    end

    specify 'accesstype, addressingtype, onreadtype and onwritetype types should be parsed by :data_type parser' do
      expect(parser).to parse('accesstype', trace: true).as(&data_type(:accesstype?))
      expect(parser).to parse('addressingtype', trace: true).as(&data_type(:addressingtype?))
      expect(parser).to parse('onreadtype', trace: true).as(&data_type(:onreadtype?))
      expect(parser).to parse('onwritetype', trace: true).as(&data_type(:onwritetype?))
    end

    specify 'user defined types should be parsed by :data_type parser' do
      type = '_'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'my_identifier'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'My_IdEnTiFiEr'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = 'x'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = '_y0123'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))

      type = '_3'
      expect(parser).to parse(type, trace: true).as(&data_type(:user_defined?, type))
    end
  end
end
