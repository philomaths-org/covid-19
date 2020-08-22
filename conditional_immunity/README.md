# Explanatory Notes
  - The file reinfection.rb estimates number of people to be reinfected assuming a particular reinfection curve. Its inputs are
    - incidences (daily new cases)
    - gamma (reinfection rate)
    - tau_r (average days between infection and recovery)
    - distribution (reinfection curve inputs are :exp or :oc43)
  - The file misc.rb contains following methods
    - gauge_effect_of_gamma which estimates effect of gamma on US COVID-19 incidence data
    - gauge_effect_of_oc43 which estimates effect of oc43 reinfection curve on US COVID-19 incidence data
    - rule_of_3 applies rule of three to US incidence data