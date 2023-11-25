# frozen_string_literal: true

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
    end

    RootInstance.define_builtin_property(:desc) do |property|
      property.target [
        :addrmap, :constraint, :field, :mem, :reg, :regfile, :signal
      ]
      property.type :string
      property.dynamic_assign true
    end

    RootInstance.define_builtin_property(:donttest) do |property|
      property.target :field
      property.type [:boolean, :bit]
      property.dynamic_assign true
    end

    RootInstance.define_builtin_property(:dontcompare) do |property|
      property.target :field
      property.type [:boolean, :bit]
      property.dynamic_assign true
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
  end
end
