--[[ Some functions for computing the expected value of a function at a given point.
]]--

require 'randomkit'
require 'optimbench.numintegr'

local integral_wrappers={}

--[[ This method computes the expected value of a noisy function at a point xo by using Monte Carlo integration.

Parameters:
 * `fun` - the noisy function
 * `xo` - the point at which the expected value shall be computed
 * `samples` - the number of samples for the Monte Carlo integration

Returns:
The expected value of the function at the point xo
--]]
function integral_wrappers.MonteCarlo(fun, xo, samples)
	samples = samples or 1000
	local fmean = 0
	for i=1, samples do
		local f, g = fun(xo)
		fmean = fmean + f
	end
	return fmean/samples
end

--[[ This method computes the expected value of a noisy function at a point xo by using Monte Carlo integration.
The difference of this function from the one above is that it uses a fixed random seed for reproducibility.

Parameters:
 * `fun` - the noisy function
 * `xo` - the point at which the expected value shall be computed
 * `samples` - the number of samples for the Monte Carlo integration

Returns:
The expected value of the function at the point xo
--]]
function integral_wrappers.MonteCarloFixedSeed(fun, xo, samples)
	local initialSeed = torch.initialSeed()
	torch.manualSeed(4294967295)
	samples = samples or 10000
	local fmean = 0
	for i=1, samples do
		local f, g = fun(xo)
		fmean = fmean + f
	end

	torch.manualSeed(initialSeed)
	return fmean/samples
end

--[[ This method computes the expected value of a noisy function at a point xo by using numerical intergration.

Parameters:
 * `fun` - the noisy function
 * `xo` - the point at which the expected value shall be computed

Returns:
The expected value of the function at the point xo
--]]
function integral_wrappers.Numerical(fun, xo)
	assert(type(fun)=='table' and fun.funnoise~=nil, 'Error numerical integration is defined only for 1-D functions')
	local xxo = xo
	if type(xxo) ~= 'number' then
		xxo = xxo[1]
	end

	if fun.name == 'maskout' then
		local f, g = fun.funnoise(xxo, 0)
		f = f * fun.pdf -- the pdf of this bernoulli is p
		return f
	end

	local wfun = function(n)
		local f,g
		f, _ = fun.funnoise(xxo, n)
		local pn = fun.pdf(n)
		local res = f * pn
		if res ~= res then
			return 0;
		end
		return res
	end

	local integral = InfiniteIntegral(wfun)
	if type(integral) == 'number' then
		return integral
	end
	return integral:squeeze()
end

--[[ Test function for checking the correctness of the integration functions above ]]--
function integral_wrappers.testIntegrals()
	local noise = require 'prototypes_noise'
	local funs = require 'prototypes_functions'
	local multivariate = require 'multivariate_functions'

	local fun = funs.FunctionGenerator({xs=-2, fs=2, fprime=-1, xe=4}, {'quad_bowl'}, {})

	print('1D bowl with zero at 1 and additive gaussian and scale 0.1')
	local fun_add = noise.gaussian_additive(0.1, fun)
	print('Numerical integration', integral_wrappers.Numerical(fun_add, 1))
	print('MC integration', integral_wrappers.MonteCarlo(fun_add, 1))
	print('Analytic result', 0.5)

	print()

	print('1D bowl with zero at 1 and multiplicative gaussian and scale 0.1')
	local fun_mul = noise.gaussian_multiplicative(0.1, fun)
	print('Numerical integration', integral_wrappers.Numerical(fun_mul, 1))
	print('MC integration', integral_wrappers.MonteCarlo(fun_mul, 1))
	print('Analytic result', 0.5*math.exp(0.1*0.1/2))

	print()

	print('2D bowl with zero at 1 and multiplicative gaussian and scale 0.1')
	fun = funs.FunctionGenerator({xs=-2, fs=1.5, fprime=-1, xe=4}, {'quad_bowl'}, {})
	local fun1 = noise.gaussian_additive(0.1, fun)
	local fun2 = noise.gaussian_additive(0.1, fun)
	local fun2D = multivariate.L2norm({fun1, fun2})

	print('MC integration', integral_wrappers.MonteCarlo(fun2D, torch.Tensor({1,1})))
	print('Analytic result', math.sqrt(2*math.pi)/20)

end

optimbench.noise_integration_prototypes = integral_wrappers
