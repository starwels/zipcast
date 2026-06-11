require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  test "index renders form without running lookup before submission" do
    stub_singleton_method(ForecastLookup, :call, ->(**_args) { raise "Lookup should not run" }) do
      get forecasts_path

      assert_response :success
      assert_select "h1", "Weather lookup by address"
    end
  end

  test "index returns unprocessable entity when address is blank" do
    get forecasts_path, params: { forecast: { address: "" } }

    assert_response :unprocessable_content
    assert_select ".flash-alert", "Enter an address to look up the forecast."
  end

  test "index rescues lookup errors and re-renders the form" do
    stub_singleton_method(ForecastLookup, :call, ->(**_args) { raise ForecastLookup::Error, "Lookup failed" }) do
      get forecasts_path, params: { forecast: { address: "1600 Amphitheatre Parkway" } }

      assert_response :unprocessable_content
      assert_select ".flash-alert", "Lookup failed"
      assert_select "input[name='forecast[address]'][value='1600 Amphitheatre Parkway']"
    end
  end
end
