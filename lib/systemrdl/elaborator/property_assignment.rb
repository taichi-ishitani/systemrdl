# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_property_assignment(node, context)
      lhs = process(node.lhs, context)
      rhs = process_assignment_rhs(lhs.first, node, context)

      if node.dynamic_assignment? && !lhs.first.dynamic_assignable?
        error 'the given LHS does not support dynamic assignment', node.position
      end

      lhs.each do |property|
        property.assigned_from?(context) &&
          (error 'no more than one assignment per scope is allowed', node.position)
        property.assign_value(rhs, context)
      end
    end

    def process_assignment_rhs(lhs, node, context)
      node.rhs.nil? &&
        (return process_rhs_less_assignment(lhs, node))

      rhs = Array(process(node.rhs, context)).first
      if match_integral_type?(lhs, rhs)
        extract_integral_rhs_value(lhs, rhs)
      elsif match_reference_type?(lhs, rhs)
        rhs
      elsif match_both_types?(lhs, rhs)
        rhs.value
      else
        error 'the given LHS and RHS are incompatible', node.position
      end
    end

    def process_rhs_less_assignment(lhs, node)
      lhs.type.include?(:boolean) ||
        (error 'no RHS is given', node.position)
    end

    def match_integral_type?(lhs, rhs)
      return false if (lhs.type & [:boolean, :bit, :longint]).empty?

      case rhs
      when Element::Value
        integral_type?(rhs.data_type)
      else
        false
      end
    end

    def extract_integral_rhs_value(lhs, rhs)
      case lhs.type
      in [*, :boolean, *]
        rhs.to_boolean
      in [*, :longint, *]
        width_based_cast(64, rhs).value
      else
        to_number(rhs).value
      end
    end

    def match_reference_type?(lhs, rhs)
      lhs.type.include?(:reference) &&
        case rhs
        when Element::ComponentInstance
          true
        when Element::Property
          rhs.ref_target?
        else
          false
        end
    end

    def match_both_types?(lhs, rhs)
      rhs.respond_to?(:data_type) && lhs.type.include?(rhs.data_type)
    end
  end
end
