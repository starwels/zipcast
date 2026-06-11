module Geocoding
  class Location
    attr_reader :address, :formatted_address, :zip_code, :latitude, :longitude

    def initialize(address:, formatted_address:, zip_code:, latitude:, longitude:)
      @address = address
      @formatted_address = formatted_address
      @zip_code = zip_code
      @latitude = latitude
      @longitude = longitude
    end
  end
end
