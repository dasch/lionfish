require 'excon'
require 'fiber'

module Lionfish
  class Coordinator
    attr_reader :objects

    def initialize(objects)
      @objects = objects
      @request_queue = []
      @blocklist = []
      @connection = ::Excon.new('http://example.com', persistent: true)
    end

    def schedule_request(env)
      @blocklist << Fiber.current
      @request_queue << [env, Fiber.current]

      value = Fiber.yield

      @blocklist.delete(Fiber.current)

      value
    end

    def blocked?(worker)
      @blocklist.include?(worker)
    end

    def map(&block)
      workers = objects.map do |object|
        Fiber.new do
          block.call(object)
        end
      end

      @values = {}

      while workers.any?(&:alive?)
        workers.each do |worker|
          @values[worker] = worker.resume if worker.alive? && !blocked?(worker)
        end

        perform_requests! unless @request_queue.empty?
      end

      workers.map {|worker| @values[worker] }
    end

    def perform_requests!
      workers = @request_queue.map {|env, worker| worker }

      requests = @request_queue.map do |env, worker|
        {
          path:    env[:url].path,
          method:  env[:method].to_s.upcase,
          headers: env[:request_headers],
          body:    env[:body].respond_to?(:read) ? env[:body].read : env[:body]
        }
      end

      @request_queue.clear

      responses = @connection.requests(requests)

      workers.zip(responses).map do |worker, response|
        @values[worker] = worker.resume(response)
      end
    end
  end
end
