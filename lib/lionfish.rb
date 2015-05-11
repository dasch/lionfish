require 'fiber'
require 'lionfish/coordinator'

module Lionfish
  def self.request(env)
    @coordinator.schedule_request(env)
  end

  def self.map(objects, &block)
    @coordinator = Coordinator.new(objects)
    @coordinator.map(&block)
  end
end
