# frozen_string_literal: true

RSpec.describe SystemRDL::Parser do
  describe 'comment' do
    let(:parser) do
      SystemRDL::Parser.new
    end

    it 'should be ignored' do
      field = <<~'F'
        // single bit field instance named “myField”
        field {} myField;
      F
      expect(parser).to parse(field)
        .as(field_definition do |f|
          f.inst id: 'myField'
        end)

      field = <<~'F'
        field {} myField; // single bit field instance named “myField”
      F
      expect(parser).to parse(field)
        .as(field_definition do |f|
          f.inst id: 'myField'
        end)

      field = <<~'F'
        field {} myField;
        // single bit field instance named “myField”
      F
      expect(parser).to parse(field)
        .as(field_definition do |f|
          f.inst id: 'myField'
        end)

      field = <<~'F'
        field /*
          // single bit field instance named “myField”
        */{} myField;
      F
      expect(parser).to parse(field)
        .as(field_definition do |f|
          f.inst id: 'myField'
        end)
    end
  end
end
