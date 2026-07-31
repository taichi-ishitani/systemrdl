# frozen_string_literal: true

module SystemRDL
  module Model
    def self.build(root)
      root.instances.map do |addrmap|
        AddrMap.new(addrmap, nil)
      end
    end
  end
end
