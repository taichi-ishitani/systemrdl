# frozen_string_literal: true

module SystemRDL
  module Model
    module_function

    def build(root)
      root.instances.map do |addrmap|
        AddrMap.new(addrmap, nil)
      end
    end
  end
end
