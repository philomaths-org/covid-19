# service to calculate prevalence
class EpiPrevalence
  RANGE = (0..14)  # matches serial_interval_density

  def initialize(incidence: nil)
    @range = RANGE
    @incidence = incidence
  end

  def call
    n = [15, incidence.length].min
    incid = incidence[-n..-1].reverse
    incid.each_with_index.map do |i, day|
      si_ccdf(day) * i
    end.sum
  end

  private

  attr_reader :range, :incidence

  # serial Interval complimentary cdf
  def si_ccdf(day)
    si_cdf.map { |d, c| [d, 1 - c] }[day][1]
  end

  def si_cdf
    sum = 0.0
    si_pdf.map { |day, p| [day, sum += p] }
  end

  def si_pdf
    range.map { |day| [day, serial_interval_density(day)] }
  end

  # uses r_instantaneous.R (EpiEstim) default serial interval, git_sha: 4752a40
  def serial_interval_density(day)
    [
      0.000000000, 0.016811722, 0.118744409, 0.195165178, 0.195693817,
      0.158864236, 0.114863178, 0.077202101, 0.049348405, 0.030409284,
      0.018222928, 0.010682907, 0.006152562, 0.003491970, 0.001957755
    ][day]
  end
end
