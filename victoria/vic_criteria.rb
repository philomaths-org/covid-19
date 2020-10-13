# models Victorian lockdown criteria
class Simul::VicCriteria

  def initialize(total_days: 60, n_samples: 10, progress_bar: true)
    @total_days = total_days
    @n_samples = n_samples
    @progress_bar = progress_bar
    @n_tests = 15_000
    @n_pop = 7_000_000
    @us_threshold = 5
    @t_window = 14
    @r_0 = 0.69 # average for victoria for September
    @t_c = 5.29 # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7276043/pdf/nihpp-2020.04.23.20075796.pdf
    @i_threshold = n_pop.to_f * us_threshold / n_tests / t_window
    k = (r_0 - 1) / t_c
    @i0 = i_threshold * exp( - k * t_window * 2)
    @actual_crossing = t_window * 2 + 1
    @crossings = []
  end

  def call
    infections = predict_infections
    average_unknowns = simulate infections
    OpenStruct.new({
      average_unknowns: average_unknowns, crossings: crossings, infections: infections,
      crossings_pdf: crossings_pdf, crossings_cdf: crossings_cdf
    })
  end

  private

  def simulate(infections)
    bar = TTY::ProgressBar.new("calculating [:bar]", total: n_samples)
    n_samples.times.map do
      bar.advance if progress_bar
      unknowns = generate_unknowns infections
      @crossings << find_crossing(unknowns)
      unknowns
    end.transpose.map(&:mean)
  end

  def crossings_pdf
    hsh = Hash.new(0)
    crossings.each { |x| hsh[x] += 1 }
    time = hsh.sort.transpose.first
    count = hsh.sort.transpose.second
    time = time.map { |t| t - actual_crossing }
    probs = count.map { |c| c.to_f / count.sum }
    [time, probs]
  end

  def crossings_cdf
    time, probs = crossings_pdf
    sum = 0.0
    cum_probs = probs.map { |c| sum += c }
    [time, cum_probs]
  end

  def generate_unknowns(infections)
    infections.map do |i|
      p_d = i.to_f / n_pop
      poisson_rand(p_d * n_tests, 1)
    end
  end

  def predict_infections
    time = (0..total_days).to_a
    k = (r_0 - 1) / t_c
    time.map { |t| i0 * exp(k * t ) }
  end

  def find_crossing(unknowns)
    return nil if unknowns.empty?
    len = unknowns.size
    return len + 1 if len < t_window
    day = len + 1
    ((t_window - 1)..len).each do |i|
      i_s = i - (t_window - 1)
      under_threshold = unknowns[i_s..i].sum  < us_threshold
      day = i if under_threshold
      break if under_threshold
    end
    day
  end

  # generate random variate of events in interval dt for Poisson distribution
  # https://hpaulkeeler.com/simulating-poisson-random-variables-direct-method
  def poisson_rand(lambda, dt)
    s = 0
    n = -1
    while s < dt do
      s += -log(rand) / lambda
      n += 1
    end
    n
  end

  attr_reader :total_days, :n_samples, :progress_bar
  attr_reader :crossings, :i_threshold
  attr_reader :n_tests, :n_pop, :us_threshold, :r_0, :i0, :t_c,  :t_window, :actual_crossing
end
