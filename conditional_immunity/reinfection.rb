# calculates number of reinfections as function of gamma
# Assumes exponential distribution
class Reinfection
	include Math

	# CDC quarantine time, https://www.cdc.gov/coronavirus/2019-ncov/hcp/duration-isolation.html
	def initialize(incidences, gamma, tau_r: 10, distribution: :exp)
		@incidences = incidences
		@gamma = gamma # reinfection rate (1/days)
		@tau_r = tau_r
		@distribution = distribution
	end

	def call
		convolve_with_distribution
	end

	def oc43
		oc43_pts
	end

	private

	def convolve_with_distribution
		n = incidences.length - 1
		incidences.each_with_index.map do |incidence, j|
			incidence * reinfection_function.call(n - j - tau_r)
		end.sum
	end

	def reinfection_function
		return lambda { |x| oc43_function(x) } if distribution == :oc43
		-> (x) {  cdf(x ) }
	end

	# cdf of exponential distribution https://en.wikipedia.org/wiki/Exponential_distribution
	def cdf(t)
		return 0 if t < 0
		1 - exp(- gamma * t)
	end

	def oc43_function(t)
		weeks = t / 7.0
		return 0.0 if weeks <= 0
		return 0.547 if weeks > 70
		x_pts = oc43_pts.transpose[0]
		y_pts = oc43_pts.transpose[1]
		i_u = x_pts.find_index { |x_c| x_c >= weeks }
		m = (y_pts[i_u] - y_pts[i_u - 1]) / (x_pts[i_u] - x_pts[i_u - 1])
		y_pts[i_u - 1] + m * (weeks - x_pts[i_u - 1])
	end

	def oc43_pts
		x_factor = oc43_raw[:x_scale][1] / oc43_raw[:x_scale][0] # weeks per inch
		y_factor = oc43_raw[:y_scale][1] / oc43_raw[:y_scale][0] # probability per inch
		oc43_raw[:pts].map do |weeks, probability|
			[(weeks * x_factor).round(3), (probability * y_factor).round(3)]
		end
	end

	def oc43_raw
		{  pts: [
							[0.0, 0.0], # [weeks, probability] in inches
							[0.45, 0.0],
							[0.55, 0.2],
							[0.7, 0.2],
							[0.75, 0.35],
							[1.15, 0.35],
							[1.26, 0.49],
							[3.8, 0.49],
							[3.9, 0.8],
							[4.3, 0.8],
							[4.5, 1.45],
							[4.85, 1.45],
							[5.1, 2.1],
							[5.3, 2.1],
							[5.67, 3.25],
							[8.1, 3.25]
						],
				x_scale: [8.1, 70], # inches to weeks
				y_scale: [4.75, 0.8] # inches to probability
		}
	end

	attr_reader :incidences, :gamma, :tau_r, :distribution
end

