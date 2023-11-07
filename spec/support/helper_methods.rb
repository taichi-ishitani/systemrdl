# frozen_string_literal: true

module SystemRDL
  module CommonHelerMethods
    def rspec_matcher?(v)
      v.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)
    end
  end

  module ParserHelperMethods
    include CommonHelerMethods

    def data_type(type)
      builtin_types = [
        :bit, :longint, :boolean, :string, :accesstype,
        :addressingtype, :onreadtype, :onwritetype
      ]
      if builtin_types.include?(type)
        be_instance_of(AST::DataType).and __send__("be_#{type}")
      else
        be_instance_of(AST::DataType).and be_user_defined.and have_attributes(data_type: identifer(type))
      end
    end

    def boolean_literal(value)
      be_instance_of(AST::BooleanLiteral).and have_attributes(value: value)
    end

    alias_method :boolean, :boolean_literal

    def number_literal(number, width: nil)
      if rspec_matcher?(number)
        number
      else
        be_instance_of(AST::NumberLiteral).and have_attributes(number: number, width: width)
      end
    end

    alias_method :number, :number_literal

    def string_literal(string)
      be_instance_of(AST::StringLiteral).and have_attributes(string: string)
    end

    alias_method :string, :string_literal

    def accesstype_literal(type)
      be_instance_of(AST::AccesstypeLiteral).and have_attributes(accesstype: type)
    end

    alias_method :accesstype, :accesstype_literal

    def onreadtype_literal(type)
      be_instance_of(AST::OnreadtypeLiteral).and have_attributes(onreadtype: type)
    end

    alias_method :onreadtype, :onreadtype_literal

    def onwritetype_literal(type)
      be_instance_of(AST::OnwritetypeLiteral).and have_attributes(onwritetype: type)
    end

    alias_method :onwritetype, :onwritetype_literal

    def addressingtype_literal(type)
      be_instance_of(AST::AddressingtypeLiteral).and have_attributes(addressingtype: type)
    end

    alias_method :addressingtype, :addressingtype_literal

    def precedencetype_literal(type)
      be_instance_of(AST::PrecedencetypeLiteral).and have_attributes(precedencetype: type)
    end

    alias_method :precedencetype, :precedencetype_literal

    def identifer(id)
      if id.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)
        id
      else
        be_instance_of(AST::ID).and have_attributes(id: id.to_sym)
      end
    end

    alias_method :id, :identifer

    def this_keyword
      be_instance_of(AST::ThisKeyword)
    end

    def reference_element(id, *array)
      array_matcher = array.empty? && be_nil || match(array)
      be_instance_of(AST::ReferenceElement)
        .and have_attributes(id: identifer(id), array: array_matcher)
    end

    def reference(*elements, property: nil)
      instance_refernce_matcher =
        if elements.empty?
          be_nil
        else
          match(elements.map { |e| reference_element(*Array(e)) })
        end
      property_matcher =
        case property
        when NilClass then be_nil
        when String then identifer(property)
        else property
        end
      be_instance_of(AST::Reference)
        .and have_attributes(instance_refernce: instance_refernce_matcher, property: property_matcher)
    end

    def cast_operation(casting_type, expression)
      be_instance_of(AST::CastOperation)
        .and have_attributes(casting_type: casting_type, expression: expression)
    end

    alias_method :cast, :cast_operation

    def unary_operation(operator, operand)
      be_instance_of(AST::UnaryOperation)
        .and have_attributes(operator: operator, operand: operand)
    end

    alias_method :u_op, :unary_operation

    def binary_operation(operator, l_operand, r_operand)
      be_instance_of(AST::BinaryOperation)
        .and have_attributes(operator: operator, l_operand: l_operand, r_operand: r_operand)
    end

    alias_method :b_op, :binary_operation

    def conditional_operation(condition, true_operand, false_operand)
      be_instance_of(AST::ConditionalOperation)
        .and have_attributes(condition: condition, true_operand: true_operand, false_operand: false_operand)
    end

    alias_method :c_op, :conditional_operation

    def property_assignment(lhs, rhs = nil, default: false)
      if default
        be_instance_of(AST::PropertyAssignment)
          .and have_attributes(lhs: lhs, rhs: rhs)
          .and be_default
      else
        be_instance_of(AST::PropertyAssignment)
          .and have_attributes(lhs: lhs, rhs: rhs)
          .and be_not_default
      end
    end

    def property_modifier(id, modifier, default: false)
      if default
        be_instance_of(AST::PropertyModifier)
          .and have_attributes(id: id, modifier: modifier)
          .and be_default
      else
        be_instance_of(AST::PropertyModifier)
          .and have_attributes(id: id, modifier: modifier)
          .and be_not_default
      end
    end

    ComponentInstances = Struct.new(:id, :type, :alias_id, :parameter_assignments, :insts) do
      def external
        self.type = :external
      end

      alias_method :__id, :id

      def id(item = nil)
        item && self.id = item
        self.__id
      end

      def parameter_assignment(item)
        (self.parameter_assignments ||= []) << item
      end

      def inst(item)
        (self.insts ||= []) << item
      end
    end

    ComponentDefinition = Struct.new(:id, :parameter_definitions, :body, :insts) do
      def initialize(id)
        self.id = id
      end

      def paraemter_definition(item)
        (self.parameter_definitions ||= []) << item
      end

      alias_method :__body, :body

      def body(item = nil)
        if item.nil?
          self.__body
        else
          self.body ||= []
          self.body << item
        end
      end

      alias_method :__insts, :insts

      def insts
        if block_given?
          self.insts ||= ComponentInstances.new
          yield(__insts)
        else
          __insts
        end
      end

      def inst(item)
        insts { |i| i.inst item }
      end
    end

    def component_definition(component_ast, id)
      definition = ComponentDefinition.new(id)
      yield definition if block_given?

      id_matcher = definition.id && identifer(definition.id)
      param_matcher = parameter_definitions(definition.parameter_definitions)
      body_mathcher = definition.body && match(definition.body)
      insts_matcher = component_instances(definition.insts)
      be_instance_of(component_ast)
        .and have_attributes(
          id: id_matcher, parameter_definitions: param_matcher,
          body: body_mathcher, insts: insts_matcher
        )
    end

    def parameter_definitions(definitions)
      return nil unless definitions

      matchers = definitions.map do |definition|
        be_instance_of(AST::ParameterDefinition)
          .and have_attributes(
            id: identifer(definition[:id]),
            data_type: data_type(definition[:data_type]), default: definition[:default]
          )
      end
      match(matchers)
    end

    def component_instances(insts = nil)
      if block_given?
        insts = ComponentInstances.new
        yield(insts)
      end

      return nil unless insts

      id_matcher = insts.id && identifer(insts.id)
      type_matcher = insts.type
      alias_id_matcher = insts.alias_id && identifer(insts.alias_id)
      param_matcher = parameter_assignments(insts.parameter_assignments)
      insts_matcher = insts.insts&.map(&method(:component_instance))&.then(&method(:match))

      be_instance_of(AST::ComponentInstances)
        .and have_attributes(
          id: id_matcher, inst_type: type_matcher,
          alias_id: alias_id_matcher, parameter_assignments: param_matcher, insts: insts_matcher
        )
    end

    def parameter_assignments(assignments)
      return nil unless assignments

      matchers = assignments.map do |assignment|
        be_instance_of(AST::ParameterAssignment)
          .and have_attributes(id: identifer(assignment[:id]), value: assignment[:value])
      end
      match(matchers)
    end

    def component_instance(inst)
      id_matcher = identifer(inst[:id])
      array_matcher = inst[:array]&.map(&method(:number))&.then(&method(:match))
      range_matcher = inst[:range]&.map(&method(:number))&.then(&method(:match))
      assignments_matcher = inst[:assignments]&.map(&method(:instnace_assignment))&.then(&method(:match))

      be_instance_of(AST::ComponentInstance)
        .and have_attributes(
          id: id_matcher, array: array_matcher,
          range: range_matcher, assignments: assignments_matcher
        )
    end

    def instnace_assignment(assignment)
      operator, operand = assignment
      be_instance_of(AST::InstanceAssignment)
        .and have_attributes(operator: operator, operand: number(operand))
    end

    def field_definition(id = nil, &b)
      component_definition(AST::FieldDefinition, id, &b)
    end

    def register_definition(id = nil, &b)
      component_definition(AST::RegisterDefinition, id, &b)
    end

    def memory_definition(id = nil, &b)
      component_definition(AST::MemoryDefinition, id, &b)
    end

    def register_file_definition(id = nil, &b)
      component_definition(AST::RegisterFileDefinition, id, &b)
    end

    def address_map_definition(id = nil, &b)
      component_definition(AST::AddressMapDefinition, id, &b)
    end
  end

  module ElaboratorHelperMethods
    include CommonHelerMethods

    def elaborate(context: nil, **input)
      parser, source = input.first
      node = Parser.new(parser).parse(source)
      Elaborator.new.process(node, context)
    end

    def create_component(parent, instance_name, array = nil, &block)
      Element::ComponentInstance.new(parent, instance_name, array, &block)
        .tap { |component| parent&.add_component(component) }
    end

    def create_proparty(component, property_name, type)
      Element::Property.new(component, property_name, type)
        .tap { |property| component.add_property(property) }
    end

    def raise_elaboration_error(message)
      raise_error(ElaborationError, match(/#{Regexp.escape(message)}/))
    end

    def match_value(value, data_type:)
      value_matcher =
        if rspec_matcher?(value)
          value
        else
          eq(value)
        end
      value_matcher.and have_attributes(data_type: data_type)
    end

    def match_number(number, width: 64)
      eq(number).and have_attributes(width: width, data_type: :number)
    end
  end
end
