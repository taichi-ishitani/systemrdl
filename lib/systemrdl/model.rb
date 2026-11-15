# frozen_string_literal: true

module SystemRDL
  module Model
    def self.build(root)
      Root.new(root, nil, {})
    end
  end
end
