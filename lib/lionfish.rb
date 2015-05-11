require 'fiber'
require 'lionfish/coordinator'

module Lionfish
  def self.request(env)
    Fiber.yield(env)
  end

  def self.map(objects, &block)
    Coordinator.new(objects).map(&block)
  end
end
