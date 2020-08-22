# service to calculate free infected individuals
class EpiFii
  def initialize(cases, deaths, prevalance)
    @cases = cases
    @deaths = deaths
    @prevalance = prevalance
  end

  def call
    hsh = EpiCdr.new(cases, deaths).call
    est = fii_calc(hsh[:est])
    # upper/lower swaps because fii proportional to reciprocal of CDR
    lower = fii_calc(hsh[:upper])
    upper = fii_calc(hsh[:lower])
    { est: est, lower: lower, upper: upper }
  end

  private

  def fii_calc(cdr)
    ((1.0 / cdr) - 1.0) * prevalance
  end

  attr_reader :deaths, :cases, :prevalance
end
