--[[ Some noise wrappers. These functions can be used to introduce different types of noise to the gradient of a deterministic function.
]]--

require 'randomkit'

local noise={}

--[[ This function implements the pdf of a gaussian with zero mean and 1 std ]]--
local function gaussPDF()
	local norm = 1/math.sqrt(2*math.pi)
	local wfun = function(x)
		return math.exp(-(x*x)/2)/norm
	end
	return wfun
end

--[[ This function implements the pdf of a standard cauchy distribution ]]--
local function cauchyPDF()
	local norm = 1/math.pi
	local noise = nil
	local wfun = function(x)
		return (1/(x*x+1)) * norm
	end
	return wfun
end

--[[ This function returns a function that adds noise to the gradient of a deterministic function ]]--
local function additive_noise(scale, fun)
	local addNoise = nil
	local wfun = function(x, noise)
		local f, g = fun(x)
		local n = noise * scale
		f = f + x*n
		g = g + n
		return f, g
	end
	return wfun
end

--[[ This function returns a function that multiplies the gradient of a deterministic function with noise ]]--
local function multiplicative_noise(scale, fun)
	local mulNoise = nil
	local wfun = function(x, noise)
		local f,g = fun(x)
		local n = math.exp(noise * scale)
		f = f * n
		g = g * n
		return f, g
	end
	return wfun
end

--[[ This function generates a new noisy version of a deterministic function, where gaussian noise is added to its gradient 

Parameters:
 * `scale` - the scale of the additive noise
 * `fun` - an instance of the deterministic function

Returns a new noisy version of the deterministic function `fun`
]]--
function noise.gaussian_additive(scale, fun)
	local fun_add_noise = additive_noise(scale, fun)
	local wfun = function(self, x)
		local noise = torch.randn(1)[1]
		return fun_add_noise(x, noise)
	end

	local myFun = setmetatable({}, {__call=wfun})
	myFun.funnoise = fun_add_noise
	myFun.pdf = gaussPDF()

	return myFun
end

--[[ This function generates a new noisy version of a deterministic function, where gaussian noise is multiplied with its gradient

Parameters:
 * `scale` - the scale of the additive noise
 * `fun` - an instance of the deterministic function

Returns a new noisy version of the deterministic function `fun`
]]--
function noise.gaussian_multiplicative(scale, fun)
	local fun_mul_noise = multiplicative_noise(scale, fun)
	local wfun = function(self, x)
		local noise = torch.randn(1)[1]
		return fun_mul_noise(x, noise)
	end

	local myFun = setmetatable({}, {__call=wfun})
	myFun.funnoise = fun_mul_noise
	myFun.pdf = gaussPDF()
	myFun.name = 'gauss'

	return myFun
end

--[[ This function generates a new noisy version of a deterministic function, where cauchy noise is added to its gradient 

Parameters:
 * `scale` - the scale of the additive noise
 * `fun` - an instance of the deterministic function

Returns a new noisy version of the deterministic function `fun`
]]--
function noise.cauchy(scale, fun)
	local fun_add_noise = additive_noise(scale, fun)
	local wfun = function(self, x)
		local cauchyNoise = torch.Tensor(1)
		cauchyNoise = randomkit.standard_cauchy(cauchyNoise)[1]
		return fun_add_noise(x, cauchyNoise)
	end

	local myFun = setmetatable({}, {__call=wfun})
	myFun.funnoise = fun_add_noise
	myFun.pdf = cauchyPDF()
	myFun.name = 'cauchy'

	return myFun
end

--[[ This function generates a new noisy version of a deterministic function, which introduce maskout noise to its gradient. The maskout noise sets the 
function's gradient to zero with a probability p, where 0<p<1.

Parameters:
 * `freq` - the probability that the gradient is zero
 * `fun` - an instance of the deterministic function

Returns a new noisy version of the deterministic function `fun`
]]--
function noise.maskout(freq, fun)

	local fun_mul_noise = multiplicative_noise(1.0, fun)
	local noise = nil
	local isTensorGrad = false
	local probabilityOfNonZero = 1- freq
	local mask = nil
	assert(probabilityOfNonZero >= 0, 'The frequency should take values between (0-1)')

	local wfun = function(self, x)
		local mask = torch.bernoulli(probabilityOfNonZero)
		local noise
		if mask then
			noise = 0
		else
			noise = -math.huge
		end

		return fun_mul_noise(x, noise)
	end

	local myFun = setmetatable({}, {__call=wfun})
	myFun.funnoise = fun_mul_noise
	myFun.pdf = probabilityOfNonZero
	myFun.name = 'maskout'

	return myFun
end

--[[ This function takes a deterministic function as input and a type of noise along with its specification and returns its corresponding noisy version.

 Parameters:
 * `noise_name` - the name of the noise to be applied
 * `fun` - an instance of the deterministic function
 * `spec` - the specification of the noise

Returns a new noisy version of the deterministic function `fun`
]]--
function noise.WrapNoise(noise_name, fun, spec)
	spec = spec or 0.1
	return noise[noise_name](spec, fun)
end

optimbench.noise_prototypes = noise

