module Weather
  class DailyForecast
    attr_reader :date, :high, :low, :condition_label

    def initialize(date:, high:, low:, condition_label:)
      @date = date
      @high = high
      @low = low
      @condition_label = condition_label
    end
  end
end
