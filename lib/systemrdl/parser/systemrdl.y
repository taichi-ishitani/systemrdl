class SystemRDL::Parser::GeneratedParser
token
  # Keywords
  KW_ABSTRACT KW_ACCESSTYPE KW_ADDRESSINGTYPE KW_ADDRMAP KW_ALIAS
  KW_ALL KW_BIT KW_BOOLEAN KW_BOTHEDGE KW_COMPACT
  KW_COMPONENT KW_COMPONENTWIDTH KW_CONSTRAINT KW_DEFAULT KW_ENCODE
  KW_ENUM KW_EXTERNAL KW_FALSE KW_FIELD KW_FULLALIGN
  KW_HW KW_INSIDE KW_INTERNAL KW_LEVEL KW_LONGINT
  KW_MEM KW_NA KW_NEGEDGE KW_NONSTICKY KW_NUMBER
  KW_ONREADTYPE KW_ONWRITETYPE KW_POSEDGE KW_PROPERTY KW_R
  KW_RCLR KW_REF KW_REG KW_REGALIGN KW_REGFILE
  KW_RSET KW_RUSER KW_RW KW_RW1 KW_SIGNAL
  KW_STRING KW_STRUCT KW_SW KW_THIS KW_TRUE
  KW_TYPE KW_UNSIGNED KW_W KW_W1 KW_WCLR
  KW_WOCLR KW_WOSET KW_WOT KW_WR KW_WSET
  KW_WUSER KW_WZC KW_WZS KW_WZT
  # Literal
  STRING
  NUMBER
  VERILOG_NUMBER
  # Identifier
  SIMPLE_ID
  # Conrol tokens
  EOS
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
  #
  # B.1 SystemRDL source text
  #
  root
    : description+ EOS {
      result = node(:root, val[0], val[0])
    }
    | __TEST_PROPERTY_ASSIGNMENT__ property_assignment EOS {
        result = val[1]
      }
    | __TEST_CONSTANT_EXPRESSION__ constant_expression EOS {
        result = val[1]
      }
  description
    : component_def

  #
  # B.3 Component definition
  #
  component_def
    : component_type id "{" component_body_elem* "}" component_inst_type component_insts ";" {
        insts = component_insts_node(val[5], val[6])
        result = node(:component_named_def, [val[0], val[1], *val[3], insts], val)
      }
    | component_type "{" component_body_elem* "}" component_inst_type component_insts ";" {
        insts = component_insts_node(val[4], val[5])
        result = node(:component_anon_def, [val[0], *val[2], insts], val)
      }
    | component_type id "{" component_body_elem* "}" component_insts ";" {
        result = node(:component_named_def, [val[0], val[1], *val[3], val[5]], val)
      }
    | component_type id "{" component_body_elem* "}" ";" {
        result = node(:component_named_def, [val[0], val[1], *val[3]], val)
      }
    | component_type "{" component_body_elem* "}" component_insts ";" {
        result = node(:component_anon_def, [val[0], *val[2], val[4]], val)
      }
    | component_inst_type component_type id "{" component_body_elem* "}" component_insts ";" {
        insts = component_insts_node(val[0], val[6])
        result = node(:component_named_def, [val[1], val[2], *val[4], insts], val)
      }
    | component_inst_type component_type "{" component_body_elem* "}" component_insts ";" {
        insts = component_insts_node(val[0], val[5])
        result = node(:component_anon_def, [val[1], *val[3], insts], val)
      }
  component_body_elem
    : component_def
    | property_assignment
    | explicit_component_inst
  component_type
    : KW_ADDRMAP | KW_REGFILE | KW_REG | KW_FIELD | KW_MEM
  explicit_component_inst
    : id component_insts ";" {
        result = node(:explicit_component_inst, val[..1], val)
      }
    | component_inst_type id component_insts ";" {
        insts = component_insts_node(val[0], val[2])
        result = node(:explicit_component_inst, [val[1], insts], val)
    }
  component_insts
    : component_inst ("," component_inst)* {
        result = node(:component_insts, to_list(val, include_separator: true), val)
      }
  component_inst
    : id component_inst_array_or_range? reset_value? address_assignment? address_stride? address_alignment? {
        result = component_inst_node(val)
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
  component_inst_type
    : KW_EXTERNAL
    | KW_INTERNAL
  component_inst_array_or_range
    : array {
        result = [val[0], nil]
      }
    | range {
        result = [nil, val[0]]
      }

  #
  # B.8 Property assignment
  #
  property_assignment
    : KW_DEFAULT prop_mod id ";" {
        result = node(:default_prop_modifier, val[1..2], val)
      }
    | prop_mod id ";" {
        result = node(:prop_modifier, val[0..1], val)
      }
    | KW_DEFAULT prop_assignment_lhs ";" {
        result = node(:default_prop_assignment, [val[1]], val)
      }
    | prop_assignment_lhs ";" {
        result = node(:prop_assignment, [val[0]], val)
      }
    | KW_DEFAULT prop_assignment_lhs "=" prop_assignment_rhs ";" {
        result = node(:default_prop_assignment, [val[1], val[3]], val)
      }
    | prop_assignment_lhs "=" prop_assignment_rhs ";" {
        result = node(:prop_assignment, [val[0], val[2]], val)
      }
    | KW_DEFAULT encode "=" id ";" {
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
    : KW_POSEDGE | KW_NEGEDGE | KW_BOTHEDGE | KW_LEVEL | KW_NONSTICKY
  prop_assignment_lhs
    : id
    | prop_keyword
  prop_keyword
    : KW_SW {
        result = node(:id, val, val)
      }
    | KW_HW {
        result = node(:id, val, val)
      }
    | KW_RCLR {
        result = node(:id, val, val)
      }
    | KW_RSET {
        result = node(:id, val, val)
      }
    | KW_WOCLR {
        result = node(:id, val, val)
      }
    | KW_WOSET {
        result = node(:id, val, val)
      }
  prop_assignment_rhs
    : constant_expression
    | precedencetype_literal {
        result = node(:precedencetype, val, val)
      }
  encode
    : KW_ENCODE {
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
    : id array {
      result = node(:instance_ref_element, val, val)
    }
    | id {
      result = node(:instance_ref_element, val, val)
    }

  #
  # B.12 Array and range
  #
  range
    : "[" constant_expression ":" constant_expression "]" {
        result = node(:range, [val[1], val[3]], val)
      }
  array
    : ("[" constant_expression "]")+ {
        result = array_node(val)
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
    : KW_LONGINT {
        result = node(:data_type, val, val)
      }
    | KW_BIT {
        result = node(:data_type, val, val)
      }

  #
  # B.15 Literals
  #
  boolean_literal
    : KW_TRUE | KW_FALSE
  accesstype_literal
    : KW_NA | KW_RW | KW_WR | KW_R | KW_W | KW_RW1 | KW_W1
  onreadtype_literal
    : KW_RCLR | KW_RSET | KW_RUSER
  onwritetype_literal
    : KW_WOSET | KW_WOCLR | KW_WOT | KW_WZS | KW_WZC | KW_WZT | KW_WCLR | KW_WSET | KW_WUSER
  addressingtype_literal
    : KW_COMPACT | KW_REGALIGN | KW_FULLALIGN
  precedencetype_literal
    : KW_HW | KW_SW

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
        result = val[1].replace_token_range(to_token_range(val))
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
        result = node(:accesstype, val, val)
      }
    | onreadtype_literal {
        result = node(:onreadtype, val, val)
      }
    | onwritetype_literal {
        result = node(:onwritetype, val, val)
      }
    | addressingtype_literal {
        result = node(:addressingtype, val, val)
      }
    | KW_THIS {
        result = node(:this, val, val)
    }
    constant_cast
      : casting_type "'" "(" constant_expression ")" {
          result = node(:cast, [val[0], val[3]], val)
        }
    casting_type
      : simple_type
      | constant_primary
      | KW_BOOLEAN {
          result = node(:data_type, val, val)
        }

  #
  # B.17 Identifiers
  #
  id
    : SIMPLE_ID {
        result = node(:id, val, val)
      }
