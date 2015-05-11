require 'excon'
require 'fiber'

module Lionfish
  class Coordinator
    attr_reader :objects

    def initialize(objects)
      @objects = objects
    end

    def map(&block)
      request_envs = []
      coordinator = Fiber.current

      workers = objects.map do |object|
        Fiber.new do
          block.call(object)
        end
      end

      workers.each do |worker|
        env = worker.resume
        request_envs << [env, worker] if env
      end

      return unless request_envs.any?

      connection = ::Excon.new('http://example.com', persistent: true)

      requests = request_envs.map do |env, worker|
        {
          path:    env[:url].path,
          method:  env[:method].to_s.upcase,
          headers: env[:request_headers],
          body:    env[:body].respond_to?(:read) ? env[:body].read : env[:body]
        }
      end

      responses = connection.requests(requests)

      request_envs.zip(responses).map do |(env, worker), response|
        worker.resume(response)
      end
    end
  end
end
