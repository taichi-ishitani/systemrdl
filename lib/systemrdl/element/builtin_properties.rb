# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

module SystemRDL
  module Element
    #
    # 5.2 General component properties
    #
    RootInstance.define_builtin_property(:name) do |property|
      property.target [
        :addrmap, :constraint, :field, :mem, :reg, :regfile, :signal
      ]
      property.type :string
      property.dynamic_assign true
      property.value ''
    end

    RootInstance.define_builtin_property(:desc) do |property|
      property.target [
        :addrmap, :constraint, :field, :mem, :reg, :regfile, :signal
      ]
      property.type :string
      property.dynamic_assign true
      property.value ''
    end

    RootInstance.define_builtin_property(:donttest) do |property|
      property.target :field
      property.type [:boolean, :bit]
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:donttest) do |property|
      property.target [:reg, :regfile, :addrmap]
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:dontcompare) do |property|
      property.target :field
      property.type [:boolean, :bit]
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:dontcompare) do |property|
      property.target [:reg, :regfile, :addrmap]
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    #
    # 5.3 Content deprecation
    #
    RootInstance.define_builtin_property(:ispresent) do |property|
      property.target [
        :addrmap, :constraint, :field, :mem, :reg, :regfile, :signal
      ]
      property.type :boolean
      property.dynamic_assign true
      property.value true
    end

    #
    # 9.4 Field access properties
    #
    RootInstance.define_builtin_property(:hw) do |property|
      property.target :field
      property.type :accesstype
      property.dynamic_assign false
      property.value :rw
    end

    RootInstance.define_builtin_property(:sw) do |property|
      property.target :field
      property.type :accesstype
      property.dynamic_assign true
      property.value :rw
    end

    #
    # 9.5 Hardware signal properties
    #
    RootInstance.define_builtin_property(:next) do |property|
      property.target :field
      property.type :reference
      property.dynamic_assign true
      property.ref_target true
    end

    RootInstance.define_builtin_property(:reset) do |property|
      property.target :field
      property.type [:bit, :reference]
      property.dynamic_assign true
      property.ref_target true
    end

    RootInstance.define_builtin_property(:resetsignal) do |property|
      property.target :field
      property.type :reference
      property.dynamic_assign true
      property.ref_target true
    end

    #
    # 9.6 Software access properties
    #
    RootInstance.define_builtin_property(:rclr) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:rset) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:onread) do |property|
      property.target :field
      property.type :onreadtype
      property.dynamic_assign true
    end

    RootInstance.define_builtin_property(:woset) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:woclr) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    RootInstance.define_builtin_property(:onwrite) do |property|
      property.target :field
      property.type :onwritetype
      property.dynamic_assign true
    end

    RootInstance.define_builtin_property(:swwe) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:swwel) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:swmod) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:swacc) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:singlepulse) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.value false
    end

    #
    # 9.7 Hardware access properties
    #
    RootInstance.define_builtin_property(:we) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:wel) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:anded) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:ored) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:xored) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:fieldwidth) do |property|
      property.target :field
      property.type :longint
      property.dynamic_assign false
    end

    RootInstance.define_builtin_property(:hwclr) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:hwset) do |property|
      property.target :field
      property.type [:boolean, :reference]
      property.dynamic_assign true
      property.ref_target true
      property.value false
    end

    RootInstance.define_builtin_property(:hwenable) do |property|
      property.target :field
      property.type :reference
      property.dynamic_assign true
      property.ref_target true
    end

    RootInstance.define_builtin_property(:hwmask) do |property|
      property.target :field
      property.type :reference
      property.dynamic_assign true
      property.ref_target true
    end

    #
    # 9.10 Miscellaneous field properties
    #
    RootInstance.define_builtin_property(:precedence) do |property|
      property.target :field
      property.type :precedencetype
      property.dynamic_assign true
      property.value :sw
    end

    RootInstance.define_builtin_property(:paritycheck) do |property|
      property.target :field
      property.type :boolean
      property.dynamic_assign false
      property.value false
    end

    #
    # 10.6 Register properties
    #
    RootInstance.define_builtin_property(:regwidth) do |property|
      property.target :reg
      property.type :longint
      property.dynamic_assign false
    end

    RootInstance.define_builtin_property(:accesswidth) do |property|
      property.target :reg
      property.type :longint
      property.dynamic_assign true
    end

    RootInstance.define_builtin_property(:errextbus) do |property|
      property.target :reg
      property.type :boolean
      property.dynamic_assign false
      property.value false
    end

    RootInstance.define_builtin_property(:shared) do |property|
      property.target :reg
      property.type :boolean
      property.dynamic_assign false
      property.value false
    end

    #
    # 12.3 Register file properties
    #
    RootInstance.define_builtin_property(:alignment) do |property|
      property.target :regfile
      property.type :longint
      property.dynamic_assign false
    end

    RootInstance.define_builtin_property(:sharedextbus) do |property|
      property.target :regfile
      property.type :boolean
      property.dynamic_assign false
      property.value false
    end

    RootInstance.define_builtin_property(:errextbus) do |property|
      property.target :regfile
      property.type :boolean
      property.dynamic_assign false
      property.value false
    end
  end
end

# rubocop:enable Metrics/ModuleLength
