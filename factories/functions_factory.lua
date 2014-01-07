--[[ This file contains the functions' factory class. In the following descriptions, the term routine will be used to refer to the 
object's functions and the term function to refer to the function it implements.
]]--
require 'torch'
--require 'torchExtensions'

local proto_funs = optimBench.function_prototypes
local proto_noise = optimBench.noise_prototypes
local proto_multivariate = optimBench.multivariate_functions
local proto_non_stationarity = optimBench.non_stationarity
local integration = optimBench.noise_integration_prototypes


local factory_ = torch.class('optimBench.factory')


--[[ The constructor of the factory class
Parameters:
 * `seed` - a random seed for reproducibality reasons
 * `name` - the name of the deterministic function assosiated with this function
 * `noisename` - the name of the noise applied on this function
 * `scalename` - the name of the scale of the function
 * `funs` - a table of tables that defines the function. For each dimension a table of univariate functions to be concatenated is being defined. 
 * `noise` - a table of tables the defines the noise applied on the function. For each dimension a table of univariate noise to be applied is being defined.
 * `ascend` -  a table of tables of size equal to the dimensionality. Each subtable includes the ascend/descend direction of the function prototypes defined in funs (one table for each dimension).
 * `norm` - the name of norm that combines the different dimensions, set it to nil for 1 dimensional functions.
 * `non_stationarity` - the type of non-stationarity along with its configuration.
 * `opt` -  a table with elements xs, xe, fs and fprime, where xs is a Tensor of size dim with the starting point of the function,
    xe the ending point, fs the value of each 1D function, fprime the value of the derivative of each 1D function.

Returns an instance of the resulting function
]]--

function factory_:__init(opt)

	self.seed = opt.seed or torch.seed()

	local noises = opt.noise or {}

	for k, v in pairs(opt) do
		self[k] = v
	end

	assert(opt.funs ~= nil, 'No prototypes have been specified')
	local funs = opt.funs or nil
	local norm = opt.norm
	assert(#funs==1 or norm~=nil, 'Multidimensional function with no norm defined')
	local ascend = opt.ascend or nil

	if not ascend then
		ascend = {}
		for i=1, #funs do
			ascend[i] = {}
		end
	end

	self.ascend = ascend

	local dim = #funs
	self.opt = opt.opt or {}

	for k, v in pairs(self.opt) do
		if type(self.opt[k]) == 'number' then
			self.opt[k] = torch.Tensor({v})
		elseif type(self.opt[k]) == 'table' then
			self.opt[k] = torch.Tensor(self.opt[k])
		end
	end

	self.opt.xs = self.opt.xs or torch.ones(dim):mul(-2)
	self.opt.xe = self.opt.xe or torch.ones(dim):mul(2)
	self.opt.fs = self.opt.fs or torch.ones(dim):mul(2)
	self.opt.fprime = self.opt.fprime or torch.ones(dim):mul(-1)


	assert(self.opt.xs:size(1)==dim, 'the dimensionality of the starting point is lower than the dimensionality of the function')
	assert(self.opt.xe:size(1)==dim, 'the dimensionality of the ending point is lower than the dimensionality of the function')
	assert(self.opt.xs:size(1)==dim, 'the dimensionality of the function values is lower than the dimensionality of the function')
	assert(self.opt.xs:size(1)==dim, "the dimensionality of the function's derivative is lower than the dimensionality of the function")

	local myFuns = {}
	local xs = self.opt.xs 
	local xe = self.opt.xe
	local fs = self.opt.fs
	local fprime = self.opt.fprime
	self.noiseless = true
	for i=1, dim do
		myFuns[i] = proto_funs.FunctionGenerator({xs=xs[i], xe=xe[i], fs=fs[i], fprime=fprime[i]}, funs[i], ascend[i])
		if noises[i] ~= nil and #noises[i]>0 then
			local scale = noises[i][2] or 0.1
			self.noiseless = false
			myFuns[i] = proto_noise.WrapNoise(noises[i][1], myFuns[i], scale)
		end
	end

	local fun

	if #myFuns > 1 then
		fun = proto_multivariate[norm](myFuns)
	else
		fun = myFuns[1]
	end

	local non_stationarity = opt.non_stationarity

	if non_stationarity then
		fun = non_stationarity.moving_target(fun, opt)
	end

	local gTensor = torch.Tensor(1)

	local ff = nil
	local gg = torch.Tensor(dim)


	local wfun

	if dim == 1 then
		wfun = function(_, x)
			local xx
			if type(x) == 'number' then
				xx = x
			else
				xx = x[1]
			end
			local f, g = fun(xx)
			ff = f
			gg[1] = g
			return ff, gg
		end
	else
		wfun = function(_, x)
			local f, g = fun(x)
			return f, g
		end
	end

	if type(fun) == 'table' then
		self.fun = {}
		for k, v in pairs(fun) do
			self.fun[k] = v
		end
		self.fun = setmetatable(self.fun, {__call=wfun})
	else
		self.fun ={} 
		self.fun = setmetatable(self.fun, {__call=wfun})
	end

	self.dim = dim
end

--[[ This routine computes the expected value of the function at its initial point.
]]--
function factory_:initValue()
	if not self.initF then
		self.initF = self:integrate(self.opt.xs)
	end
	return self.initF
end

--[[ This routine rotates a multivariate function. If a rotation matrix rotMatrix is passed as an argument then this will be used, otherwise 
a new random rotation matrix will be generated. 
]]--
function factory_:rotate(rotMatrix)
	self.rotated = true
	assert(self.dim>1, 'Cannot rotate a 1D function')
	local rotMat
	local fun
	local mt = getmetatable(self.fun)
	
	local myfun = mt.__call
	
	local original_fun = function(x) return myfun(nil, x) end

	fun, rotMat = proto_multivariate.Rotation(original_fun, self.dim, self.seed, rotMatrix)

	mt.__call = function(_, x) return fun(x) end

	
	local xs = rotMat * self.opt.xs
	local xe = rotMat * self.opt.xe
	local temp = torch.cat(xs, xe, 2)
	self.opt.xs = temp:min(2):squeeze():add(-1000)
	self.opt.xe = temp:max(2):squeeze():add(1000)

end

--[[ This routine Curls the gradient field of a multivariate function.
]]--
function factory_:curl(scale)
	scale = scale or 1
	self.curled = true
	assert(self.dim>1, 'Cannot rotate a 1D function')
	local rotMat
	local fun
	local mt = getmetatable(self.fun)
	
	local myfun = mt.__call
	
	local original_fun = function(x) return myfun(nil, x) end

	fun, rotMat = proto_multivariate.Curl(original_fun, scale, self.seed)

	mt.__call = function(_, x) return fun(x) end

end

--[[ This routine generated a hash key descriptor for the function. This descriptor is the concatenation of the function name, the noise name and the scale name of the 
function
]]--
function factory_:hash()
	if self.hashkey ~= nil then 
		return self.hashkey
	end
	if self.name and self.noisename and self.scalename then
		self.hashkey = self.name ..'_'..self.noisename .. '_'..self.scalename
		if self.rotated then
			self.hashkey = self.hashkey .. '_rotated'
		end
		if self.curled then
			self.hashkey = self.hashkey .. '_curled'
		end
		return self.hashkey
	end
	return nil
end

--[[ This routine offsets the function by a given vector xo. ]]--
function factory_:offset(xo)
	assert(xo~=nil, 'Specify xo offset vector')
	if self.dim > 1 then
		self.fun = proto_multivariate.OffSet(self.fun, xo)
	else
		self.fun = proto_funs.OffSet(self.fun, xo)
	end
end

--[[ This routine computes the expected value of the function at a given point xo. ]]--
function factory_:integrate(xo)
	if not self.fun then
		self:restore()
	end
	if self.noiseless then
		local f, g = self.fun(xo)
		return f
	end
	if self.dim == 1 then
		return integration.Numerical(self.fun, xo)
	else
		return integration.MonteCarlo(self.fun, xo)
	end
end

--[[ This routine implements an abrupt_switching non stationarity ]]--
function factory_:abrupt_switching(fun, stepsize)
	stepsize = stepsize or 100
	self.fun = proto_non_stationarity.abrupt_switching({self.fun, fun.fun}, stepsize)
	if fun.opt.xs < self.opt.xs then
		self.opt.xs = fun.opt.xs
	end
	if fun.opt.xe > self.opt.xe then
		self.opt.xe = fun.opt.xe
	end
end

--[[ This is a metamethod, which is defined in order to be possible to cal an object's instance as a function ]]--
function factory_:__call(x)
	if self.fun == nil then
		self:restore()
	end
	return self.fun(x)
end

--[[ Resets the object ]]--
function factory_:restore()
	local instance = factories.factory({
		seed= self.seed,
		name= self.name,
		noisename= self.noisename,
		scalename= self.scalename,
		funs= self.funs,
		noise= self.noise,
		ascend= self.ascend,
		norm= self.norm,
		non_stationarity= self.non_stationarity,
		opt= self.opt
	})
	for k, v in pairs(instance) do
		self[k] = v
	end
	local self_mt= getmetatable(self)
	local instance_mt = getmetatable(instance)

	for k, v in pairs(instance_mt) do
		self_mt[k] = v
	end

end

--[[ This routine destroys the instance of the associated function of the object ]]--
function factory_:clear()
	local mt = getmetatable(self.fun)
	for k, v in pairs(mt) do
		mt[k] = nil
	end
	self.fun = nil
	collectgarbage('collect')
end

--[[ Generates a pretty name for the function ]]--
function factory_:prettyName()
	if not self.name then
		return nil
	end

	local str = 'Name: '
	local name = self.name
	for k in name:gmatch('%w+') do
		str = str .. ' ' .. k
	end

	if self.noisename then
		str = str .. '    Noise: '

		local noisename = self.noisename

		for k in noisename:gmatch('%w+') do
			str = str .. ' ' .. k
		end
	end

	if self.scalename then
		str = str .. '    Scale: '

		local scalename = self.scalename

		for k in scalename:gmatch('%w+') do
			str = str .. ' ' .. k
		end
	end

	return str

end

--[[ This routine plots the function. In the case of multivariate functions an numerical argument can be passed in order to define what projection 
of the function shall be plotted. ]]--
function factory_:plot(arg)
	if not self.fun then
		self:restore()
	end
	if self.dim > 2 and arg == nil then
		print('Could not plot functions of dimension higher than 2')
		return
	end
	require 'gnuplot'

	local vals = torch.cat(self.opt.xs, self.opt.xe, 1)
	local xs = vals:min()
	local xe = vals:max()

	local x = torch.linspace(xs, xe)
	local nsamples = x:size(1)

	print(self:prettyName())

	local title = self:prettyName() or 'Unknown' 

	if self.dim == 1 then
		local y = x:clone()
		for i=1, nsamples do
			y[i] = self.fun(x[i])
		end
		gnuplot.plot({title, x, y, '-'})

	elseif type(arg) ~= 'number' then
		local x1 = torch.Tensor(nsamples*nsamples)
		local x2 = x1:clone()

		local yy = torch.Tensor(nsamples, nsamples)
		local k =1
		for i=1, nsamples do
			for j=1, nsamples do
				yy[i][j] = self.fun(torch.Tensor({x[i], x[j]}))
				x1[k] = x[i]
				x2[k] = x[j]
				k=k+1
			end
		end
		x1 = x1:resize(nsamples, nsamples)
		x2 = x2:resize(nsamples, nsamples)
		gnuplot.splot({x1, x2, yy})
		--io.read()
	end
end

-- hack around class torch issue
optimxBench.factory = optimx.factory
