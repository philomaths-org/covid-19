# service to calculate free infected individuals
class EpiFii
  def initialize(cases, deaths, prevalance, n_samples: 10)
    @cases = cases
    @deaths = deaths
    @prevalance = prevalance
    @n_samples = n_samples
  end

  def call
    cdrs = EpiCdr.new(cases, deaths).call
    est = estimate_mean(cdrs)
    # upper/lower swaps because fii proportional to reciprocal of CDR
    lower = fii_simple_calc(cdrs[:upper])
    upper = fii_simple_calc(cdrs[:lower])
    { est: est, lower: lower, upper: upper }
  end

  private

  def estimate_mean(cdrs)
    fiis = sample_fiis(cdrs)
    puts "fiis mean: #{fiis.mean} min: #{fiis.min} fiis max: #{fiis.max}"
    fiis.mean
  end

  def sample_fiis(cdrs)
    trunc = TruncateNormalRand(cdrs[:est], cdrs[:lower], cdrs[:upper], z_score: 1.96)
    n_samples.times.map do
      cdr = trunc.call
      fii_simple_calc cdr
    end
  end

  def fii_simple_calc(cdr)
    ((1.0 / cdr) - 1.0) * prevalance
  end

  attr_reader :deaths, :cases, :prevalance
end
