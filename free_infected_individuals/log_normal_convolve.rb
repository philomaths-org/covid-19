# service to perform convolution of a vec with lognormal density function
# as needed by
# https://cmmid.github.io/topics/covid19/global_cfr_estimates.html
class LogNormalConvolve
  include Math

  def initialize(mean = 13.0, std = 12.7, z_mean: nil, z_median: nil, max_delay: -1)
    @mu = log(mean.to_f**2 / sqrt(mean**2 + std**2))
    @sigma = sqrt(log(1.0 + std**2 / mean**2))
    return unless z_mean.present?
    @mu = log(z_median)
    @sigma = sqrt(2 * (log(z_mean) - mu))
    @max_delay = max_delay # set to -1 to do all delays
  end

  def call(vec)
    range = (0..max_delay)
    vec.reverse[range].each_with_index.map do |e, j|
      e * case_delay(j)
    end.sum
  end

  # log normal cdf https://en.wikipedia.org/wiki/Log-normal_distribution
  def case_delay(x)
    cdf(x + 1.0) - cdf(x)
  end

  def cdf(x)
    0.5 * erfc(-(log(x) - mu) / sigma / sqrt(2))
  end

  # log normal density https://en.wikipedia.org/wiki/Log-normal_distribution
  def density(x)
    return 0.0 if x <= 0
    exp(-(log(x) - mu)**2 / (2 * sigma**2)) / (x * sigma * sqrt(2 * PI))
  end

  private

  attr_reader :mean, :std, :mu, :sigma, :max_delay

  
end