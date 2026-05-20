ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "net/http"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def with_env(overrides)
      original = overrides.transform_values { nil }

      overrides.each_key do |key|
        original[key] = ENV[key]
      end

      overrides.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end

      yield
    ensure
      original.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end

    def http_response(code:, body:, message: "OK")
      response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code).new("1.1", code, message)
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, body)
      response
    end

    def stub_singleton_method(object, method_name, callable = nil)
      singleton_class = object.singleton_class
      previous_method = object.method(method_name)

      singleton_class.define_method(method_name) do |*args, **kwargs, &method_block|
        if callable.respond_to?(:call)
          callable.call(*args, **kwargs, &method_block)
        else
          callable
        end
      end

      yield
    ensure
      singleton_class.define_method(method_name, previous_method)
    end
  end
end
