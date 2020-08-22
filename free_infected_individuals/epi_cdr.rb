# service to estimate number of free infected individuals
# https://cmmid.github.io/topics/covid19/global_cfr_estimates.html

class EpiCdr
  include Math

  # default ccfr from Meyerowitz  https://doi.org/10.1101/2020.05.03.20089854
  def initialize(cases, deaths, max_delay: 56, ccfr: [0.0053, 0.0068, 0.0082 ])
    @ccfr_estimates_range = { lower: ccfr[0], mid: ccfr[1], upper: ccfr[2] }
    @rate_ref = ccfr_estimates_range[:mid]
    @cases = cases
    @deaths = deaths
    @z_mean = z_mean
    @z_median = z_median
    @max_delay = max_delay # set to -1 to have no truncation
  end

  def call
    hsh = cdrs_with_ci
    { est: g_min(hsh[:estimates]), lower: g_min(hsh[:lowers]), upper: g_max(hsh[:uppers]) }
  end

  def cdrs_with_ci
    estimates = [cdrs_raw[:cdr_low][:est], cdrs_raw[:cdr_mid][:est], cdrs_raw[:cdr_high][:est]]
    lowers = [cdrs_raw[:cdr_low][:lower], cdrs_raw[:cdr_mid][:lower], cdrs_raw[:cdr_high][:lower]]
    uppers = [cdrs_raw[:cdr_low][:upper], cdrs_raw[:cdr_mid][:upper], cdrs_raw[:cdr_high][:upper]]
    { estimates: estimates, lowers: lowers, uppers: uppers }
  end

  private

  def cdrs_raw
    cdr_low_est = cdr(distribution: :low).last
    cdr_low_ci = cdr_ci
    cdr_mid_est = cdr(distribution: :mid).last
    cdr_mid_ci = cdr_ci
    cdr_high_est = cdr(distribution: :high).last
    cdr_high_ci = cdr_ci
    {
      cdr_low: { est: cdr_low_est, lower: cdr_low_ci[:lower], upper: cdr_low_ci[:upper] },
      cdr_mid: { est: cdr_mid_est, lower: cdr_mid_ci[:lower], upper: cdr_mid_ci[:upper] },
      cdr_high: { est: cdr_high_est, lower: cdr_high_ci[:lower], upper: cdr_high_ci[:upper] },
    }
  end

  def cdr(distribution: :mid)
    @z_mean = distribution_parameters[distribution][:z_mean]
    @z_median = distribution_parameters[distribution][:z_median]
    cdr_calc
  end

  def cdr_calc
    ccfr = ccfr_calc
    ccfr.map do |r|
      next rate_ref / r if r.nan?
      [rate_ref / r, 1.0].min
    end
  end

  def ccfr_calc
    incidence_adj = adjust_incidence
    @cases_known = cumulative_sum incidence_adj
    cases_known.zip(deaths).map do  |c, d|
      next Float::NAN if d < 10
      next Float::NAN if c <= 0 || c < d
      d.to_f / c
    end
  end

  def cdr_ci
    binomial_ci_limits = binomial_ci_95(deaths.last, cases_known.last)
    no_result = binomial_ci_limits[:uq].nan? || binomial_ci_limits[:lq].nan? || deaths.last < 10
    return { lower: Float::NAN, upper: Float::NAN } if no_result
    lower = [ccfr_estimates_range[:lower] / binomial_ci_limits[:uq], 1.0].min
    upper = [ccfr_estimates_range[:upper] / binomial_ci_limits[:lq], 1.0].min
    { lower: lower, upper: upper }
  end

  def adjust_incidence
    n = incidence.size - 1
    lnc = LogNormalConvolve.new(z_mean: z_mean, z_median: z_median, max_delay: max_delay)
    (0..n).map do |i|
      lnc.call(incidence[0..i])
    end
  end

  def cumulative_sum(ary)
    sum = 0
    ary.map{|x| sum += x}
  end

  # generalized minimum that handles NaN
  def g_min(vec)
    return Float::NAN if vec.map(&:nan?).include? true
    vec.min
  end

  def g_max(vec)
    return Float::NAN if vec.map(&:nan?).include? true
    vec.max
  end

  def incidence
    return cases if cases.length == 1
    cases.each_cons(2).map { |cm, c| [c - cm, 0].max }.prepend(cases.first)
  end

  def cap_at_one(x)
    return x if x.nan?
    [x, 1.0].min
  end

  # binomial 95% confidence intervals using normal approximation
  # https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval
  def binomial_ci_95_normal_approximation(successes, trials)
    p = successes.to_f / trials
    return { lq: Float::NAN, uq: Float::NAN } if p >= 1.0
    z = 1.96
    t = z * sqrt(p * (1 - p) / trials)
    { lq: p - t, uq: p + t }
  end

  # bionomial 95% confidence interval using Clopper-Pearson (exact) method
  # calculated using beta distribution method
  # https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval
  def binomial_ci_95(successes, trials)
    require 'rubystats/beta_distribution'
    p = successes.to_f / trials
    return { lq: Float::NAN, uq: Float::NAN } if p >= 1.0 || p.nan?
    x = successes
    n = trials
    return { lq: Float::NAN, uq: Float::NAN } if x <= 0 || (n - x + 1) <= 0
    lq = Rubystats::BetaDistribution.new(x,n - x + 1).icdf(0.025)
    return { lq: Float::NAN, uq: Float::NAN } if (x + 1) <= 0 || (n - x) <= 0
    uq = Rubystats::BetaDistribution.new(x + 1 ,n - x).icdf(0.975)
    { lq: lq, uq: uq }
  end

  def distribution_parameters
    {
      low: { z_mean: 8.7, z_median: 6.7 },
      mid: { z_mean: 13.0, z_median: 9.1 },
      high: { z_mean: 20.9, z_median: 13.7 }
    }

  end

  attr_reader :rate_ref, :cases, :deaths, :cases_known, :ccfr_estimates_range,
              :z_mean, :z_median, :distribution, :max_delay
end
