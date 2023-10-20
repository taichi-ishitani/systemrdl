# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_boolean_literal(node, _context)
      Element::BooleanValue.new(node.value, node.position)
    end

    def on_number_literal(node, _context)
      if node.width
        check_literal_bit_length(node)
        Element::BitValue.new(node.number, node.width, node.position)
      else
        Element::LongintValue.new(node.number, node.position)
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
      Element::StringValue.new(node.string, node.position)
    end

    def on_accesstype_literal(node, _context)
      Element::AccessTypeValue.new(node.accesstype, node.position)
    end

    def on_onreadtype_literal(node, _context)
      Element::OnreadtypeValue.new(node.onreadtype, node.position)
    end

    def on_onwritetype_literal(node, _context)
      Element::OnwritetypeValue.new(node.onwritetype, node.position)
    end

    def on_addressingtype_literal(node, _context)
      Element::AddressingtypeValue.new(node.addressingtype, node.position)
    end

    def on_precedencetype_literal(node, _context)
      Element::PrecedencetypeValue.new(node.precedencetype, node.position)
    end
  end
end
