--[[ An optimisation algorithm wrapper class is defined in this file. 
]]--

require 'torch'
require 'optim'

local algo = torch.class('optimBench.algo')

--[[ This method is the constructor

Parameters:
 * `algoname` - the name of the algorithm
 * `optim_algo_name` - the name of the function that implements the algorithm in optim or optimx OR an instance of the implementation function
 * `config` - a table with the configuration of the algorithm

Example:
	local sgd_wrapper = factories.algo('sgd', 'sgd', nil)

--]]

function algo:__init(algoname, optim_algo_name, config)
	self.name = algoname
	self.config = config or {}
	self.optim_algo_name = optim_algo_name or algoname
end

--[[ This method returns a hash name for the object. The hash name is computed by concatenating the name of the algorithm and 
its parameters configuration into a single string. For example, sgdlearningRate0.1 for an sgd algorithm with learning rate equal to 0.1.

Returns:
 1. a string with the hash name of the object. 

--]]

function algo:hash()
	if self.hashValue then
		return self.hashValue
	end
	self.hashValue=self.name
	for k, v in pairs(self.config) do
		self.hashValue = self.hashValue .. k .. tostring(v)
	end
	return self.hashValue
end

--[[ This method runs the optimisation algorithm which is assosiated to the object on the function fun, starting at point xo for number of steps equal to steps.
It returns a list of x points and corresponding function values which where computed during the optimisation process.

Parameters:
 * `fun` - an instance of the function to be optimised
 * `xo` - the starting point for initiating the optimisation process
 * `steps` - the number of steps

Returns:
 1. `xvalues` - a list of x points where the f function was evaluated
 2. `fvalues` - a list of the corresponding f values
--]]
function algo:minimise(fun, xo, steps)
	self.steps = steps or 1000
	self.error = nil
	assert(xo ~= nil, 'Provide starting point !')

	if type(xo)=='number' then
		xo = torch.Tensor({xo})
	end
	
	local algorithm = optim[self.optim_algo_name] or optimx[self.optim_algo_name] or self.optim_algo_name -- in case it is a function !!

	if not algorithm or type(algorithm) ~= 'function' then
		error('Could not find algorithm implementation !')
	end

	local dim = xo:nDimension()
	local index = 2
	local current_x = xo:clone()
	local next_x = current_x:clone()
	local fvalues = {}
	local xvalues = {}
	local state = {}
	local config = table.copy(self.config)
	local axmin 
	for i=1, steps do
		local x_temp, fs, axmin_temp = algorithm(fun, current_x, config, state)
		if self.name == 'asgd' then
			axmin = axmin_temp
		end
		fs = fs[1]
		--local myf, myg = fun(current_x)

		next_x:copy(x_temp)
		x_temp = nil
		if fs~=fs or fs > 1e10 then
			self.steps = i
			if fs ~= fs then 
				self.error = 'Nan'
			else
				self.error = 'explosion'
			end
			fvalues[self.steps] = fs
			xvalues[self.steps] = axmin or current_x
			if type(xvalues[self.steps]) ~= 'number' then
				xvalues[self.steps] = xvalues[self.steps]:squeeze()
			end
			return fvalues, xvalues
		end

		if i%index == 0 then
			fvalues[i] = fs
			xvalues[i] = axmin or current_x
			if type(xvalues[i]) ~= 'number' then
				xvalues[i] = xvalues[i]:squeeze()
			end
			index = index * 2
		end
		current_x:copy(next_x)
	end

	if fvalues[steps] == nil then
		fvalues[steps], _ = fun(current_x)
		xvalues[steps] = axmin or current_x
		if type(xvalues[steps]) ~= 'number' then
				xvalues[steps] = xvalues[steps]:squeeze()
		end
	end

	return fvalues, xvalues
end

--[[ This method returns a copy of the algorithm's state
--]]
function algo:getState()
	local statecopy = {}
	for k, v in pairs(self.config) do
		statecopy[k] = v
	end
	return statecopy
end

--[[ This method returns a copy of object
--]]
function algo:clone()
	return factories.algo(self.name, self.optim_algo_name, self:getState())
end
