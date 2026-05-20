require "json"
require "net/http"

module Geocoding
  class GoogleGeocoder
    Result = Struct.new(
      :address,
      :formatted_address,
      :zip_code,
      :latitude,
      :longitude,
      keyword_init: true
    )

    class Error < StandardError; end
    class MissingApiKeyError < Error; end
    class NoResultsError < Error; end
    class MissingZipCodeError < Error; end
    class RequestError < Error; end

    ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json".freeze

    def self.call(address:)
      new(address:).call
    end

    def initialize(address:)
      @address = address.to_s.strip
      @api_key = load_api_key
    end

    def call
      raise MissingApiKeyError, "Missing google geocoding API key in Rails credentials." if api_key.empty?

      response = perform_request
      parse_response(response)
    end

    private

    attr_reader :address, :api_key

    def load_api_key
      Rails.application.credentials.dig(:google, :geocoding_api_key).to_s
    end

    def perform_request
      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(address:, key: api_key)

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise RequestError, "Google Geocoding request failed with #{response.code}."
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
      raise RequestError, "Google Geocoding request failed: #{error.message}"
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      result = payload.fetch("results", []).first

      raise NoResultsError, "No location found for that address." if result.blank?

      zip_code = extract_zip_code(result.fetch("address_components", []))
      raise MissingZipCodeError, "That address did not resolve to a ZIP code." if zip_code.blank?

      location = result.fetch("geometry").fetch("location")

      Result.new(
        address:,
        formatted_address: result.fetch("formatted_address"),
        zip_code:,
        latitude: location.fetch("lat"),
        longitude: location.fetch("lng")
      )
    rescue JSON::ParserError
      raise RequestError, "Google Geocoding returned an invalid response."
    end

    def extract_zip_code(components)
      component = components.find do |entry|
        entry.fetch("types", []).include?("postal_code")
      end

      component&.fetch("long_name", nil)
    end
  end
end
