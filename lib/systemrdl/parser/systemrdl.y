class SystemRDL::Parser::GeneratedParser
token
  # Keywords
  ABSTRACT ACCESSTYPE ADDRESSINGTYPE ADDRMAP ALIAS
  ALL BIT BOOLEAN BOTHEDGE COMPACT
  COMPONENT COMPONENTWIDTH CONSTRAINT DEFAULT ENCODE
  ENUM EXTERNAL FALSE FIELD FULLALIGN
  HW INSIDE INTERNAL LEVEL LONGINT
  MEM NA NEGEDGE NONSTICKY NUMBER
  ONREADTYPE ONWRITETYPE POSEDGE PROPERTY R
  RCLR REF REG REGALIGN REGFILE
  RSET RUSER RW RW1 SIGNAL
  STRING STRUCT SW THIS TRUE
  TYPE UNSIGNED W W1 WCLR
  WOCLR WOSET WOT WR WSET
  WUSER WZC WZS WZT
  # Literal
  STRING
  NUMBER
  VERILOG_NUMBER
  # Identifier
  SIMPLE_ID
  # Conrol tokens for test
  __TEST_PROPERTY_ASSIGNMENT__
  __TEST_CONSTANT_EXPRESSION__

prechigh
  nonassoc UOP
  left     "**"
  left     "*" "/" "%"
  left     "+" "-"
  left     "<<" ">>"
  left     "<" "<=" ">" ">="
  left     "==" "!="
  left     "&"
  left     "^" "~^" "^~"
  left     "|"
  left     "&&"
  left     "||"
  right    "?" ":"
preclow

rule
  root
    : component_def
    | __TEST_PROPERTY_ASSIGNMENT__ property_assignment {
        result = val[1]
      }
    | __TEST_CONSTANT_EXPRESSION__ constant_expression {
        result = val[1]
      }

  #
  # B.3 Component definition
  #
  component_def
    : component_type id "{" component_body_elem* "}" component_insts ";" {
        result = node(:component_named_def, [val[0], val[1], *val[3], val[5]], val)
      }
    | component_type id "{" component_body_elem* "}" EXTERNAL component_insts ";" {
        insts = val[6].replace_type(:external_component_insts)
        result = node(:component_named_def, [val[0], val[1], *val[3], insts], val)
      }
    | EXTERNAL component_type id "{" component_body_elem* "}" component_insts ";" {
        insts = val[6].replace_type(:external_component_insts)
        result = node(:component_named_def, [val[1], val[2], *val[4], insts], val)
      }
    | component_type id "{" component_body_elem* "}" ";" {
        result = node(:component_named_def, [val[0], val[1], *val[3]], val)
      }
    | component_type "{" component_body_elem* "}" component_insts ";" {
        result = node(:component_anon_def, [val[0], *val[2], val[4]], val)
      }
    | component_type "{" component_body_elem* "}" EXTERNAL component_insts ";" {
        insts = val[5].replace_type(:external_component_insts)
        result = node(:component_anon_def, [val[0], *val[2], insts], val)
      }
    | EXTERNAL component_type "{" component_body_elem* "}" component_insts ";" {
        insts = val[5].replace_type(:external_component_insts)
        result = node(:component_anon_def, [val[1], *val[3], insts], val)
      }
  component_body_elem
    : component_def
    | property_assignment
    | explicit_component_inst
  component_type
    : ADDRMAP | REGFILE | REG | FIELD | MEM
  explicit_component_inst
    : id component_insts ";" {
        result = node(:explicit_component_inst, val[0..1], val)
      }
  component_insts
    : component_inst ("," component_inst)* {
        result = node(:component_insts, to_list(val, include_separator: true), val)
      }
  component_inst
    : id component_inst_array_or_range? reset_value? address_assignment? address_stride? address_alignment? {
        result = component_inst_node(val)
      }
  component_inst_array_or_range
    : array+ {
        result = [val[0], nil]
      }
    | range {
        result = [nil, val[0]]
      }
  reset_value
    : "=" constant_expression {
        result = node(:reset_value, [val[1]], val)
      }
  address_assignment
    : "@" constant_expression {
        result = node(:address_assignment, [val[1]], val)
      }
  address_stride
    : "+=" constant_expression {
        result = node(:address_stride, [val[1]], val)
      }
  address_alignment
    : "%=" constant_expression {
        result = node(:address_alignment, [val[1]], val)
      }

  #
  # B.8 Property assignment
  #
  property_assignment
    : DEFAULT prop_mod id ";" {
        result = node(:default_prop_modifier, val[1..2], val)
      }
    | prop_mod id ";" {
        result = node(:prop_modifier, val[0..1], val)
      }
    | DEFAULT prop_assignment_lhs ";" {
        result = node(:default_prop_assignment, [val[1]], val)
      }
    | prop_assignment_lhs ";" {
        result = node(:prop_assignment, [val[0]], val)
      }
    | DEFAULT prop_assignment_lhs "=" prop_assignment_rhs ";" {
        result = node(:default_prop_assignment, [val[1], val[3]], val)
      }
    | prop_assignment_lhs "=" prop_assignment_rhs ";" {
        result = node(:prop_assignment, [val[0], val[2]], val)
      }
    | DEFAULT encode "=" id ";" {
        result = node(:default_prop_assignment, [val[1], val[3]], val)
      }
    | encode "=" id ";" {
        result = node(:prop_assignment, [val[0], val[2]], val)
      }
    | prop_ref ";" {
        result = node(:post_prop_assignment, [val[0]], val)
      }
    | prop_ref "=" prop_assignment_rhs ";" {
        result = node(:post_prop_assignment, [val[0], val[2]], val)
      }
    | encode_ref "=" id ";" {
        result = node(:post_prop_assignment, [val[0], val[2]], val)
      }
  prop_mod
    : POSEDGE | NEGEDGE | BOTHEDGE | LEVEL | NONSTICKY
  prop_assignment_lhs
    : id
    | prop_keyword
  prop_keyword
    : SW {
        result = node(:id, val, val)
      }
    | HW {
        result = node(:id, val, val)
      }
    | RCLR {
        result = node(:id, val, val)
      }
    | RSET {
        result = node(:id, val, val)
      }
    | WOCLR {
        result = node(:id, val, val)
      }
    | WOSET {
        result = node(:id, val, val)
      }
  prop_assignment_rhs
    : constant_expression
    | precedencetype_literal {
        result = node(:precedence_type, val, val)
      }
  encode
    : ENCODE {
        result = node(:id, val, val)
      }
  encode_ref
    : instance_ref "->" encode {
        result = node(:prop_ref, [val[0], val[2]], val)
      }

  #
  # B.11 Reference
  #
  instance_ref
    : instance_ref_element ("." instance_ref_element)* {
        result = node(:instance_ref, to_list(val, include_separator: true), val)
      }
  prop_ref
    : instance_ref "->" id {
        result = node(:prop_ref, [val[0], val[2]], val)
      }
    | instance_ref "->" prop_keyword {
        result = node(:prop_ref, [val[0], val[2]], val)
      }
  instance_or_prop_ref
    : prop_ref
    | instance_ref
  instance_ref_element
    : id array* {
      result = node(:instance_ref_element, to_list(val, include_separator: false), val)
    }

  #
  # B.12 Array and range
  #
  range
    : "[" constant_expression ":" constant_expression "]" {
        result = node(:range, [val[1], val[3]], val)
      }
  array
    : "[" constant_expression "]" {
        result = node(:array, [val[1]], val)
      }

  #
  # B.13 Concatenation
  #
  constant_concatenation
    : "{" constant_expression ("," constant_expression)* "}" {
        result = node(:concatenation, to_list(val[1..-2], include_separator: true), val)
      }
  constant_multiple_concatenation
    : "{" constant_expression constant_concatenation "}" {
      result = node(:replication, val[1..2], val)
    }

  #
  # B.14 Data types
  #
  simple_type
    : LONGINT {
        result = node(:data_type, val, val)
      }
    | BIT {
        result = node(:data_type, val, val)
      }

  #
  # B.15 Literals
  #
  boolean_literal
    : TRUE | FALSE
  accesstype_literal
    : NA | RW | WR | R | W | RW1 | W1
  onreadtype_literal
    : RCLR | RSET | RUSER
  onwritetype_literal
    : WOSET | WOCLR | WOT | WZS | WZC | WZT | WCLR | WSET | WUSER
  addressingtype_literal
    : COMPACT | REGALIGN | FULLALIGN
  precedencetype_literal
    : HW | SW

  #
  # B.16 Expressions
  #
  constant_expression
    : constant_primary
    | "!" constant_expression = UOP {
        result = uop_node(val)
      }
    | "+" constant_expression = UOP {
        result = uop_node(val)
      }
    | "-" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~" constant_expression = UOP {
        result = uop_node(val)
      }
    | "&" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~&" constant_expression = UOP {
        result = uop_node(val)
      }
    | "|" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~|" constant_expression = UOP {
        result = uop_node(val)
      }
    | "^" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~^" constant_expression = UOP {
        result = uop_node(val)
      }
    | "^~" constant_expression = UOP {
        result = uop_node(val)
      }
    | constant_expression "&&" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "||" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "==" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "!=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">>" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<<" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "&" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "|" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "^" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "~^" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "^~" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "*" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "/" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "%" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "+" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "-" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "**" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "?" constant_expression ":" constant_expression {
        result = node(:conditional_operation, [val[0], val[2], val[4]], val)
      }
  constant_primary
    : primary_literal
    | constant_concatenation
    | constant_multiple_concatenation
    | "(" constant_expression ")" {
        result = val[1].replace_range(to_token_range(val))
      }
    | constant_cast
    | instance_or_prop_ref
  primary_literal
    : boolean_literal {
        result = node(:boolean, val, val)
      }
    | STRING {
        result = node(:string, val, val)
      }
    | NUMBER {
        result = node(:number, val, val)
      }
    | VERILOG_NUMBER {
        result = node(:verilog_number, val, val)
      }
    | accesstype_literal {
        result = node(:access_type, val, val)
      }
    | onreadtype_literal {
        result = node(:on_read_type, val, val)
      }
    | onwritetype_literal {
        result = node(:on_write_type, val, val)
      }
    | addressingtype_literal {
        result = node(:addressing_type, val, val)
      }
    | THIS {
        result = node(:this, val, val)
    }
    constant_cast
      : casting_type "'" "(" constant_expression ")" {
          result = node(:cast, [val[0], val[3]], val)
        }
    casting_type
      : simple_type
      | constant_primary
      | BOOLEAN {
          result = node(:data_type, val, val)
        }

  #
  # B.17 Identifiers
  #
  id
    : SIMPLE_ID {
        result = node(:id, val, val)
      }
