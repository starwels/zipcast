module Weather
  class Forecast
    attr_reader :temperature,
      :temperature_unit,
      :apparent_temperature,
      :wind_speed,
      :wind_speed_unit,
      :condition_label,
      :fetched_at,
      :daily_high,
      :daily_low,
      :daily_periods

    def initialize(
      temperature:,
      temperature_unit:,
      apparent_temperature:,
      wind_speed:,
      wind_speed_unit:,
      condition_label:,
      fetched_at:,
      daily_high:,
      daily_low:,
      daily_periods:
    )
      @temperature = temperature
      @temperature_unit = temperature_unit
      @apparent_temperature = apparent_temperature
      @wind_speed = wind_speed
      @wind_speed_unit = wind_speed_unit
      @condition_label = condition_label
      @fetched_at = fetched_at
      @daily_high = daily_high
      @daily_low = daily_low
      @daily_periods = daily_periods
    end
  end
end
