
  def gauge_effect_of_gamma(gamma, tau_r:)
    country = Country.find_by_name 'US'
    incidences = country.incidences
    puts "gamma: #{gamma}, t_r: #{1 / gamma}, tau_r: #{tau_r}, date: #{country.cases_a.last[0]}"
    reinfections = Reinfection.new(incidences, gamma, tau_r: tau_r).call
    puts "Number of reinfections: #{reinfections.round}, cases: #{country.cases_a.last[1]}"
  end

  def gauge_effect_of_oc43
    country = Country.find_by_name 'US'
    incidences = country.incidences
    puts "oc43 virus date: #{country.cases_a.last[0]}"
    reinfections = Reinfection.new(incidences, nil, distribution: :oc43).call
    puts "Number of reinfections: #{reinfections.round}"
  end

  def rule_of_three
    country = Country.find_by_name 'US'
    puts "Rule of Three, date: #{country.cases_a.last[0]}"
    n = country.cases_a.last[1]
    puts "total: #{n}, probability: #{(n/3).round(0)}"
  end



