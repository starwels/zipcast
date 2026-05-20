require "test_helper"

class Geocoding::GoogleGeocoderTest < ActiveSupport::TestCase
  FakeHttp = Struct.new(:response) do
    attr_accessor :use_ssl, :open_timeout, :read_timeout

    def request(_request)
      response
    end
  end

  test "returns a resolved location with zip code and coordinates" do
    payload = {
      results: [
        {
          formatted_address: "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
          geometry: { location: { lat: 37.422, lng: -122.084 } },
          address_components: [
            { long_name: "94043", types: [ "postal_code" ] }
          ]
        }
      ]
    }

    fake_http = FakeHttp.new(http_response(code: "200", body: JSON.generate(payload)))

    with_google_geocoding_api_key("test-key") do
      stub_singleton_method(Net::HTTP, :new, fake_http) do
        result = Geocoding::GoogleGeocoder.call(address: "1600 Amphitheatre Parkway")

        assert_equal "94043", result.zip_code
        assert_equal 37.422, result.latitude
        assert_equal(-122.084, result.longitude)
      end
    end
  end

  test "raises when api key is missing" do
    with_google_geocoding_api_key(nil) do
      error = assert_raises(Geocoding::GoogleGeocoder::MissingApiKeyError) do
        Geocoding::GoogleGeocoder.call(address: "1600 Amphitheatre Parkway")
      end

      assert_equal "Missing google geocoding API key in Rails credentials.", error.message
    end
  end

  test "raises when no zip code is returned" do
    payload = {
      results: [
        {
          formatted_address: "Mountain View, CA, USA",
          geometry: { location: { lat: 37.422, lng: -122.084 } },
          address_components: []
        }
      ]
    }

    fake_http = FakeHttp.new(http_response(code: "200", body: JSON.generate(payload)))

    with_google_geocoding_api_key("test-key") do
      stub_singleton_method(Net::HTTP, :new, fake_http) do
        error = assert_raises(Geocoding::GoogleGeocoder::MissingZipCodeError) do
          Geocoding::GoogleGeocoder.call(address: "Mountain View")
        end

        assert_equal "That address did not resolve to a ZIP code.", error.message
      end
    end
  end
end
