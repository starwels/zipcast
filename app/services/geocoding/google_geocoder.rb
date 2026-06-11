require "json"
require "net/http"

module Geocoding
  class GoogleGeocoder
    class Error < StandardError; end
    class MissingApiKeyError < Error; end
    class NoResultsError < Error; end
    class MissingZipCodeError < Error; end
    class RequestError < Error; end

    ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json".freeze
    POSTAL_CODE_TYPE = "postal_code".freeze
    REQUEST_TIMEOUT_SECONDS = 5

    ADDRESS_COMPONENTS_KEY = "address_components".freeze
    FORMATTED_ADDRESS_KEY = "formatted_address".freeze
    GEOMETRY_KEY = "geometry".freeze
    LATITUDE_KEY = "lat".freeze
    LOCATION_KEY = "location".freeze
    LONG_NAME_KEY = "long_name".freeze
    LONGITUDE_KEY = "lng".freeze
    RESULTS_KEY = "results".freeze
    TYPES_KEY = "types".freeze

    INVALID_RESPONSE_MESSAGE = "Google Geocoding returned an invalid response.".freeze
    MISSING_API_KEY_MESSAGE = "Missing google geocoding API key in Rails credentials.".freeze
    MISSING_ZIP_CODE_MESSAGE = "That address did not resolve to a ZIP code.".freeze
    NO_RESULTS_MESSAGE = "No location found for that address.".freeze

    def self.call(address:)
      new(address:).call
    end

    def initialize(address:)
      @address = address.to_s.strip
      @api_key = load_api_key
    end

    def call
      raise MissingApiKeyError, MISSING_API_KEY_MESSAGE if api_key.empty?

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
      http.open_timeout = REQUEST_TIMEOUT_SECONDS
      http.read_timeout = REQUEST_TIMEOUT_SECONDS

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise RequestError, "Google Geocoding request failed with #{response.code}."
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
      raise RequestError, "Google Geocoding request failed: #{error.message}"
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      result = payload.fetch(RESULTS_KEY, []).first

      raise NoResultsError, NO_RESULTS_MESSAGE if result.blank?

      zip_code = extract_zip_code(result.fetch(ADDRESS_COMPONENTS_KEY, []))
      raise MissingZipCodeError, MISSING_ZIP_CODE_MESSAGE if zip_code.blank?

      location = result.fetch(GEOMETRY_KEY).fetch(LOCATION_KEY)

      Location.new(
        address:,
        formatted_address: result.fetch(FORMATTED_ADDRESS_KEY),
        zip_code:,
        latitude: location.fetch(LATITUDE_KEY),
        longitude: location.fetch(LONGITUDE_KEY)
      )
    rescue JSON::ParserError
      raise RequestError, INVALID_RESPONSE_MESSAGE
    end

    def extract_zip_code(components)
      component = components.find do |entry|
        entry.fetch(TYPES_KEY, []).include?(POSTAL_CODE_TYPE)
      end

      component&.fetch(LONG_NAME_KEY, nil)
    end
  end
end
