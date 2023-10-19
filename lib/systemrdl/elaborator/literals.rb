# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_boolean_literal(node, _context)
      Element::Value.new(:boolean, node.value)
    end

    def on_number_literal(node, _context)
      if node.width
        check_literal_bit_length(node)
        Element::NumberValue.new(:bit, node.number, node.width)
      else
        Element::NumberValue.new(:longint, node.number, nil)
      end
    end

    def check_literal_bit_length(node)
      return if node.number.bit_length <= node.width

      message =
        'value of number does not fit within the specified bit width: ' \
        "#{node.verilog_number}"
      error(message, node.position)
    end

    def on_string_literal(node, _context)
      Element::Value.new(:string, node.string)
    end

    def on_accesstype_literal(node, _context)
      Element::AccessTypeValue.new(node.accesstype)
    end

    def on_onreadtype_literal(node, _context)
      Element::OnreadtypeValue.new(node.onreadtype)
    end

    def on_onwritetype_literal(node, _context)
      Element::OnwritetypeValue.new(node.onwritetype)
    end

    def on_addressingtype_literal(node, _context)
      Element::AddressingtypeValue.new(node.addressingtype)
    end

    def on_precedencetype_literal(node, _context)
      Element::PrecedencetypeValue.new(node.precedencetype)
    end
  end
end
