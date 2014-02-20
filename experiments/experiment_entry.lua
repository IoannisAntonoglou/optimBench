--[[ This file contains the definition of an experiment class. An experiment is defined by a function instance and an optimisation algorithm instance ]]--
require 'torch'

--[[ A table with the definition of different colours
]]--
local colours = {
	red = {1, 0, 0},
	green = {0, 1, 0},
	yellow = {2, 2, 0},
	orange = {2, 1, 0},
	violet = {1, 0, 2}, 
	blue = {0, 0, 1}
}


local experiment = torch.class('optimbench.experiment_entry')

--[[ This function produces a list of seeds for a random generator. The function is deterministic for reproducibility reasons ]]--
local function seedGenerator(N)
	local startSeed = 15485863
	local seeds = {}
	for i=1,N do 
		seeds[i] = math.floor(startSeed*i*math.log(startSeed*i))
	end
	return seeds
end

--[[The constructor of an experiment instance 

Parameters:
 * algo - an optimisation algorithm object (factories.algo object)
 * fun - a function object (factories.factory object)
 * repetitions - number of times to repeat the experiment
 * steps - number of steps to run the optimisation algorithm 

Returns an instance of the experiment

]]--
function experiment:__init(algo, fun, repetitions, steps)
	self.fun = fun
	self.funname = fun.name
	self.algoname = algo.name
	self.algo = algo
	self.opt = algo.state
	self.repetitions = repetitions or 10
	self.steps = steps or 100
	self.seeds = seedGenerator(self.repetitions)
end

--[[ This functions runs an experiment for times equal to repetition. For each repetition it computes the expected value of the function at the point 
it converged. Finally, it computes the median value of these expected values, and this value wil be used for assessing the performance of the algorithm 
on this function. 
]]--
function experiment:run()

	local fmins = {}
	local xmins = {}
	self.x0 = self.fun.opt.xs:clone()
	self.f0 = self.fun.opt.fs:clone()
	local x0 = self.x0:clone()
	for i, v in pairs(self.seeds) do
		torch.manualSeed(v)
		x0:copy(self.x0)
		local fvalues, xvalues = self.algo:minimise(self.fun, x0, self.steps)
		if self.algo.error == nil then
			table.insert(xmins, xvalues[self.algo.steps])
		end
	end
	if #xmins < self.repetitions/2 then
		self.error = 'Numerical Instability'
		self.fmin = math.huge
		return 
	end

	for i=1, #xmins do
		fmins[i] = self.fun:integrate(xmins[i])
	end

	local indices


	fmins, indices = torch.Tensor(fmins):sort()

	self.fmins = fmins

	local repet = fmins:size(1)
	local dim = self.fun.dim

	if repet % 2 == 0 then
		repet = math.floor(repet/2)
		self.fmin = (fmins[repet] + fmins[repet+1])/2
		if dim == 1 then
			self.xmin = (xmins[indices[repet]]+xmins[indices[repet+1]])/2
		else
			self.xmin = torch.add(xmins[indices[repet]], xmins[indices[repet+1]]):div(2)
		end
	else	
		repet = math.ceil(repet/2)
		self.fmin = fmins[repet]
		if dim == 1 then
			self.xmin = (xmins[indices[repet]]+xmins[indices[repet+1]])/2
		else
			self.xmin = torch.add(xmins[indices[repet]], xmins[indices[repet+1]]):div(2)
		end
	end

	return fmins
end

--[[ Resets an experiment instance ]]--
function experiment:restore()
	self.fun:restore()
	self.algo:restore()
end

--[[ Returns the median expected value of the function along with the point assosiated with this value 
]]--
function experiment:expectedValue()
	return self.fmin, self.xmin
end

--[[ Qualitatively assess the experiment given the initial expected value of the function and the bestValue achieved with Stochastic Gradient Descent. It assosiates
the experiment to a colour that describes the algorithm's performance ]]--
function experiment:qualitativeAssess(initValue, bestValue)
	local fmins = self.fmins

	if not self.fmin then
		fmins = self:run()
	end
	self.colour = nil

	if self.fmin > 1e10 or self.fmin~= self.fmin then
		self.normalisedValue = math.huge
		self.colour = colours.red
		return
	end

	if self.fmin < -1e10 then
		self.fmin = -1e10
	end

	if bestValue < -1e10 then
		bestValue = -1e10
	end

	self.normalisedValue = (self.fmin - initValue)/(bestValue - initValue)

	if self.normalisedValue ~= self.normalisedValue then
		self.colour = colours.red
		return
	end


	if self.normalisedValue <= 0.1 then
		self.colour = colours.orange
	elseif self.normalisedValue > 0.1 then
		if not fmins then
			fmins = self:run()
			if not fmins then
				--print(self.fun:hash(), self.algo:hash())
				self.colour = colours.red
				return
			end
		end
		local poorExperiments = 0

		for i=1, fmins:size(1) do
			local normalised = (fmins[i] - initValue)/(bestValue - initValue)
			if normalised < 0.1 then
				poorExperiments = poorExperiments + 1
			end
		end

		if fmins:size(1) == self.repetitions then
			if poorExperiments > 0.25*self.repetitions then
				self.colour = colours.yellow
			else
				if self.normalisedValue > 2 then
					self.colour = colours.blue
				else
					self.colour = colours.green
				end
			end
		else
			self.colour = colours.violet
		end
		self.validExperiments = fmins:size(1)
		return 
	end
end

--optimbench.benchmarking.experiment_entry = optimbench.experiment_entry
--optimbench.experiment_entry = nil
