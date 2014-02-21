--[[ This file defines the database object of all the experiments. This is the main object to be used by the user, and it involves all the necessary functions
for assessing the performance of an algorithm in a list of function prototypes
]]--
require 'paths'
require 'image'

local algorithms_list = optimbench.algorithms_list
local functions_list = optimbench.functions_list


local experiments_db = torch.class('optimbench.experimentsDB')

--[[ This is the object's constructor. It creates all the indexing tables which are necessary for retrieving and filtering the results in the database
efficiently. 

Parameters:
 * `opt` - a table of parameters:
  - `repetitions`, the number of repetitions for each experiment
  - `steps`, the number of optimisation steps of each algorithm for each function. 
  - `referencePathFile`, the path to a serialised table of reference values.

Example:
local exp = optimx.experimentsDB({repetitions=10, steps=100, referencePathFile=nil})

]]--
function experiments_db:__init(opt)
	opt = opt or {}
	self.functions_indexing = {}
	self.algorithms_indexing = {}
	self.noise_indexing = {}
	self.scale_indexing = {}
	self.non_stat_indexing = {}
	self.repetitions = opt.repetitions or 10
	self.steps = opt.steps or 100
	self.referenceFun = '{quad_bowl|1|}_{gauss_add_normal|1|}_{normal|1|}_{None}_{normal}_{normal}_{normal}'
	if opt.referencePathFile then
		if paths.filep(opt.referencePath) then
			local f = torch.DiskFile(opt.referencePathFile, 'r'):binary()
			self.referenceExperiments = f:readObject()
			f:close()
		end
	else
		if paths.filep('referenceValues') then
			local f = torch.DiskFile('referenceValues', 'r'):binary()
			self.referenceExperiments = f:readObject()
			f:close()
		end
	end

end



--[[ This function runs all the experiments for a set of functions and a set of algorithms

Parameters:
 * `funs` - a list of functions to be optimised, if this parameter is nil then the list of all the available functions that have been defined is used instead.
 * `algos` - a list of algorithms to be assessed, if this parameter is nil then the list of all the available algorithms that have been defined is used instead.

Example:
exp:runExperiments()

]]--
function experiments_db:runExperiments(funs, algos)
	local i =0

	local funs_list = funs or functions_list
	local algos_list = algos or algorithms_list

	self.experiments = self.experiments or {}
	for kf, vf in pairs(funs_list) do
		self.functions_indexing[vf.name] = self.functions_indexing[vf.name] or {}
		self.noise_indexing[vf.noisename] = self.noise_indexing[vf.noisename] or {}
		self.scale_indexing[vf.scalename] = self.scale_indexing[vf.scalename] or {}
		self.non_stat_indexing[vf.non_statname] = self.scale_indexing[vf.non_statname] or {}
		self.functions_indexing[vf.name][kf] = true
		self.noise_indexing[vf.noisename][kf] = true
		self.scale_indexing[vf.scalename][kf] = true
		self.non_stat_indexing[vf.non_statname][kf] = true

		for ka, va in pairs(algos_list) do
			self.experiments[ka] = self.experiments[ka] or {}
			self.algorithms_indexing[va.name] = self.algorithms_indexing[va.name] or {}
			self.algorithms_indexing[va.name][ka] = true

			self.experiments[ka][kf] = optimbench.experiment_entry(va, vf, self.repetitions, self.steps)
			i=i+1
			print(ka, kf, i)
			self.experiments[ka][kf]:run()
		end
	end
end

--[[ This function extracts a set of experiments based on the parameter configuration of the assosiated algorithms. 

Parameters: 
 * `allFilters` - table with parameter values
 * `experiments` - list of experiments to be considered

For example if `allFilters` is equal to {learningRate=0.9}, then all the experiments in the `experiments` list for which the associated algorithm has 
learningRate equal to 0.9 will be extracted.
]]--
function experiments_db:extract_opt_experiments(allFilters, experiments)
	local entries = {}
	for k, v in pairs(experiments) do
		local opt = k.opt
		if opt then
			local valid = true
			for filter, value in pairs(allFilters) do
				if opt[filter] ~= value then
					valid = false
					break
				end
			end
			entries[k] = valid or nil
		end
	end
	return entries
end
--[[ This function retrieves a set of experiments from the database given a set of filters.

Parameters:
 * `filters_arg` - table of filters:
  - `fun`, a list of function names
  - `algo`, a list of algorithm names
  - `noise`, a list of noise types
  - `scale`, a list of scale types
  - `non_stat`, a list of non stationarity types
  - `any valid algorithm parameter`

Special care should be taken with function and algorithm names. For example if the function name is equal to 'abs' then all the different abs functions with different
types of noise and scale will be retrieved. However, if the function name is equal to 'abs_noiseless_normal' then only one function with no noise and normal scale will
be retrieved. The last one is equivalent to setting the `fun` argument to 'abs', the `noise` argument to 'noiseless' and the `scale` argument to normal, but it is faster.
In the case of the `algo` parameter, if the provided name is 'sgd' then all 'sgd' algorithms with different learning rate values will be retrieved, while
if the algorithm name is 'sgdlearningRate0.1' then only the sgd algorithm with learning rate 0.1 will be retrieved. The last one is equivalent to setting the 
learningRate argument to 0.1, only significantly faster. 
]]--
function experiments_db:filter(filters_arg)
	local filters = table.copy(filters_arg)
	if not filters then
		return {}
	end
	if not self.experiments then
		print('Populate the DB first, by running the run function')
		return
	end

		-- combine all parameters together
	local numParams = 0
	local allFiltersOpt = {}
	for k, v in pairs(filters) do
		if k~='fun' and k~='noise' and k~='scale' and k~='algo' then
			allFiltersOpt[k] = v
			numParams = numParams + 1
		end
	end

	if numParams == 0 then
		allFiltersOpt = nil
	end

	local oldentries = {}
	for k, v in pairs(self.experiments) do
		for kk, vv in pairs(v) do
			oldentries[vv] = true
		end
	end

	local processByOrder = {'algo', 'fun', 'noise', 'scale', 'non_stat', 'rest'}

	for _, key in pairs(processByOrder) do
		local newentries = {}
		if filters[key] ~= nil or ( key == 'rest' and allFiltersOpt ) then
			local value = filters[key]
			if key == 'algo' then

				if type(value)~= 'table' then
					value = {value}
				end

				for _, vv in pairs(value) do
					if algorithms_list[vv] ~= nil then
						for k, v in pairs(oldentries) do
							newentries[k] = newentries[k] or (k.algo:hash() == vv)
						end
					elseif self.algorithms_indexing[vv] ~= nil then
						for k, v in pairs(oldentries) do
							newentries[k] = newentries[k] or self.algorithms_indexing[vv][k.algo:hash()]
						end
					else
						error('Could not find algorithm '..value..' in the DB')
					end
				end

			elseif key == 'fun' then

				if type(value) ~= 'table' then
					value = {value}
				end
				for _, vv in pairs(value) do
					if functions_list[vv] ~= nil then
						for k, v in pairs(oldentries) do
							newentries[k] = newentries[k] or (k.fun:hash() == vv)
						end
					elseif self.functions_indexing[vv] ~= nil then
						for k, v in pairs(oldentries) do
							newentries[k] = newentries[k] or self.functions_indexing[vv][k.fun:hash()]
						end
					else
						error('Could not find function '..vv..' in the DB')
					end
				end

			elseif key == 'noise' or key == 'scale' or key == 'non_stat' then

				local indexing = self[key..'_indexing']

				if type(value) ~= 'table' then
					value = {value}
				end
				for _, vv in pairs(value) do
					if indexing[vv] ~= nil then
						for k, v in pairs(oldentries) do
							newentries[k] = newentries[k] or (k.fun[key..'name'] == vv)
						end
					else
						error('No such '..key..' in the DB ')
					end
				end
			else
				newentries = self:extract_opt_experiments(allFiltersOpt, oldentries)
			end

			oldentries = {}
			for entry, _ in pairs(newentries) do
				oldentries[entry] = true
			end

		end
	end
	local entries = {}
	for k, _ in pairs(oldentries) do
		table.insert(entries, k)
	end
	return entries
end

--[[ Resets the experiments Database ]]--
function experiments_db:restore()
	for k, v in pairs(self.experiments) do
		for kk, vv in pairs(v) do
			vv:restore()
		end
	end
end

--[[ This method computes the reference values for each function. However, it is important that the database includes all the necessary SGD experiments ]]--
function experiments_db:ComputeReferenceValues()

	if self.referenceExperiments then
		return 
	end

	self.referenceExperiments = {}

	local sgd_variants = self.algorithms_indexing['sgd']
	
	assert(sgd_variants~=nil, 'No reference values computed !')

	local available_functions = {}
	for k, v in pairs(self.functions_indexing) do
		for kk, vv in pairs(v) do
			available_functions[kk] = functions_list[kk]
		end
	end

	for kf, vf in pairs(available_functions) do
		local fInit = vf:initValue()
		local fbest = math.huge
		local kbest = nil
		for ka, va in pairs(sgd_variants) do
			local exp = self.experiments[ka][kf]
			if exp and exp.fmin < fbest then 
				fbest = exp.fmin
				kbest = ka
			end
		end
		if fbest < math.huge and fbest < fInit then
			self.referenceExperiments[kf] = self.experiments[kbest][kf]
		else
			for ka, va in pairs(self.experiments) do
				self.experiments[ka][kf] = nil
			end
		end
	end
end

--[[ This function removes the experiments for which no reference value could be computed, these experiments are being discarded ]]--
function experiments_db:cleanDB()
	for kf, vf in pairs(functions_list) do
		if not self.referenceExperiments[kf] then
			for ka, va in pairs(self.experiments) do
				if self.experiments[ka][kf] then
					self.experiments[ka][kf]=nil
				end
			end
			if self.functions_indexing[kf] ~= nil then
				self.functions_indexing[kf] = nil
			elseif self.functions_indexing[vf.name]~= nil then
				self.functions_indexing[vf.name][kf] = nil 
			end
		end
	end
	self.cleaned = true
end

--[[ This function qualitatively assess the performance of a set of experiments. This set of experiments is defined by the argument filters (see function  filter) ]]--
function experiments_db:assessPerformance(filters)
	if not self.referenceExperiments then
		self:ComputeReferenceValues()
	end

	if not self.cleaned then
		self:cleanDB()
	end

	if not filters then
		for ka, va in pairs(self.experiments) do
			for kf, vf in pairs(va) do
				if not self.experiments[ka][kf].colour then
					local fInit = self.referenceExperiments[kf].fun:initValue()
					local fbest = self.referenceExperiments[kf].fmin
					self.experiments[ka][kf]:qualitativeAssess(fInit, fbest)
				end
			end
		end
	else
		local experiments = self:filter(filters)
		for _, exp in pairs(experiments) do
			if not exp.colour then
				local fInit = exp.fun:initValue()
				local fbest = self.referenceExperiments[exp.fun:hash()].fmin
				exp:qualitativeAssess(fInit, fbest)
			end
		end
	end
end

function experiments_db:_nicePlot(funs, algos, blocks, data)

	require 'qtwidget'
	local z = data:size(1)
	local xdim = data:size(2)
	local ydim = data:size(3)

	local zoom = 0

	local xoffset = 100
	local yoffset = 50

	local wydim = zoom*xdim + yoffset
	local wxdim = zoom*ydim + xoffset

	local win = qtwidget.newwindow(wxdim, wydim, 'Display')

	--[[
		Add the descriptions
	]]--

	for label, pos in pairs(blocks) do
		local relxpos = pos[1]
		local relypos = pos[2]

		local xpos, ypos

		xpos = yoffset/2
		ypos = xoffset/2

		if relxpos>0 then
			xpos = zoom * relxpos + yoffset
		end

		if relypos>0 then
			ypos = zoom * relypos + xoffset
		end

		local label_len = label:len()/2

		local x = xpos - label_len
		local y = ypos - label_len
		
		win:moveto(y, x)
		win:show(label)
	end

	win:gbegin()
	image.display({image=data, win=win, zoom=zoom, x=xoffset, y=yoffset})
end

function experiments_db:_DBsortFuns(fun)

	local all_variants_funs

	if self.functions_indexing[fun] then
		all_variants_funs = self.functions_indexing[fun]
	elseif fun == 'all' then
		all_variants_funs = {}
		for k, v in pairs(self.functions_indexing) do
			for kk, vv in pairs(v) do
				all_variants_funs[kk] = true
			end
		end
	end

	if all_variants_funs == nil then
		if functions_list[fun] == nil then
			print('Invalid function ', fun)
			return nil, nil
		end
		return {fun=self.referenceExperiments[fun].algo.config.learningRate}
	end

	all_variants = {}
	local len = 0
	for k, _ in pairs(all_variants_funs) do
		all_variants[k] = self.referenceExperiments[k].algo.config.learningRate
		len = len+1
	end

	local all_variants = table.sortByValue(all_variants)

	return all_variants, len

end

function experiments_db:_DBsortAlgos(algo)

	local all_variants = self.algorithms_indexing[algo]

	if all_variants == nil then
		if self.experiments[algo] == nil then
			error('Invalid algorithm ', algo)
		end
		return {algo=self.experiments[algo][self.referenceFun].fmin}
	end

	all_variants = {}
	local len=0
	for k, _ in pairs(self.algorithms_indexing[algo]) do
		if self.experiments[k][self.referenceFun] then
		all_variants[k] = self.experiments[k][self.referenceFun].fmin
		len=len+1
		end
	end

	all_variants = table.sortByValue(all_variants)

	return all_variants, len

end

--[[ This function plots a set of colormaps that describe the performance of different algorithms on different functions. 

Parameters:
 * `funs` - a list of function names/types
 * `algos` - a list of algorithms

The final plot is composed of blocks where each block depicts the performance of an algorithm on a family of functions. 
]]--
function experiments_db:plotExperiments(funs, algos)
	local fun_blocks = {}

	local algo_blocks = {}

	local ydim = 0
	local len

	local margin = 10

	if not (#algos > 0) then
		for ka, _ in pairs(self.algorithms_indexing) do
			table.insert(algos, ka)
		end
	end

	if not (#funs > 0) then
		self:assessPerformance({algo=algos})
		table.insert(funs, 'all')
	else
		self:assessPerformance({fun=funs, algo=algos})
	end

	for _, fun in pairs(funs) do
		fun_blocks[fun], len = self:_DBsortFuns(fun)
		if len then
			ydim = ydim + len + margin
		else
			funs[_] = nil
		end
	end


	local xdim = 0

	for _, algo in pairs(algos) do
		algo_blocks[algo], len = self:_DBsortAlgos(algo)
		xdim = xdim + len + margin
	end


	local data = torch.Tensor(3, xdim, ydim)

	local x = 1
	local y = 1
	
	local blocks = {}
	local xs, xe
	local ys, ye

	for _, algo in pairs(algos) do
		xs = x
		for _, a in pairs(algo_blocks[algo]) do
			y = 1
			for _, fun in pairs(funs) do
				ys = y
				for _, f in pairs(fun_blocks[fun]) do
					local r, g, b
					r, g, b = unpack(self.experiments[a][f].colour)
					data[1][x][y] = r
					data[2][x][y] = g
					data[3][x][y] = b
					y=y+1
				end

				ye = y - 1
				blocks[fun] = {0, (ys+ye)/2}
				-- margin
				data[{{}, {x}, {y, y+margin-1}}]:fill(2)
				y = y+margin

			end
			x = x+1
		end
		xe = x - 1
		blocks[algo] = {(xs+xe)/2, 0}
		-- margin
		data[{{}, {x, x+margin-1}, {}}]:fill(2)
		x = x+margin
	end

--	print(data:size())
	self:_nicePlot(funs, algos, blocks, data)
end

--[[ This function serialises an experiment database object and it saves it in the file defined by the argument `filename`. ]]--
function experiments_db:save(filename)
	local i=1
	local functions_index = {}

	for k, v in pairs(functions_list) do
		functions_index[k] = i
		i=i+1
	end
	i=1

	local algorithms_index = {}

	for k,v in pairs(algorithms_list) do
		algorithms_index[k] = i
		i=i+1
	end

	local indices = {}

	local fmin = {}

	local dims = {}

	local fmins = {}

	local repets = {}

	local xmin = {}

	local max_dim = 0

	local max_repet = 0

	i = 1

	for k, v in pairs(self.experiments) do
		for kk, e in pairs(v) do
			
			if e.fmin and algorithms_index[e.algo:hash()] and functions_index[e.fun:hash()] then
				local fun_index = functions_index[e.fun:hash()]
				local algo_index = algorithms_index[e.algo:hash()]
				indices[2*i-1] = fun_index
				indices[2*i] = algo_index
				fmin[i] = e.fmin

				fmins[i] = e.fmins

				xmin[i] = e.xmin

				if not xmin[i] then
					xmin[i]=0
					dims[i] = 0
				else
					dims[i] = e.fun.dim
				end

				if dims[i] > max_dim then
					max_dim = dims[i]
				end

				if not fmins[i] then
					repets[i] = 0
					fmins[i] = torch.Tensor(e.repetitions):fill(math.huge)
				else
					repets[i] = fmins[i]:size(1)
				end

				if repets[i] > max_repet then
					max_repet = repets[i]
				end

				i=i+1
			end
		end
	end

	local num_experiments = i-1

	indices = torch.Tensor(indices):resize(num_experiments, 2)

	fmin = torch.Tensor(fmin)

	dims = torch.Tensor(dims)

	local xmin_tensor = torch.zeros(#xmin, max_dim)

	local fmins_tensor = torch.zeros(#fmins, max_repet)

	repets = torch.Tensor(repets)

	for j=1, num_experiments do

		local xx = xmin[j]

		local dim = dims[j]

		if type(xx) == 'number' then
			xmin_tensor[j][1] = xx
		else
			xmin_tensor[{{j}, {1, dim}}]:copy(xx)
		end

		local repet = math.max(repets[j], fmins[j]:size(1))

		fmins_tensor[{{j}, {1, repet}}]:copy(fmins[j])

	end

	local new_functions_index = {}

	for k, v in pairs(functions_index) do
		new_functions_index[v] = k
	end

	functions_index = new_functions_index

	local new_algorithms_index = {}

	for k,v in pairs(algorithms_index) do
		new_algorithms_index[v] = k
	end

	algorithms_index = new_algorithms_index

	local f = torch.DiskFile(filename, 'w'):binary()

	f:writeObject(indices)
	f:writeObject(xmin_tensor)
	f:writeObject(dims)
	f:writeObject(fmin)
	f:writeObject(fmins_tensor)
	f:writeObject(repets)
	f:writeObject(functions_index)
	f:writeObject(algorithms_index)
	f:close()
end

--[[ This function loads an experiment database that is stored in the file defined by the argument `filename` ]]--
function experiments_db:load(filename)
	local f = io.open(filename)

	if f == nil then
		print('Could not find ', filename)
		return
	end

	f:close()

	f = torch.DiskFile(filename, 'r'):binary()

	local indices = f:readObject()
	local xmin = f:readObject()
	local dims = f:readObject()
	local fmin = f:readObject()
	local fmins = f:readObject()
	local repets = f:readObject()
	local functions_index = f:readObject()
	local algorithms_index = f:readObject()
	
	f:close()

	self.experiments = {}

	for i=1, fmin:size(1) do

		local fun = functions_list[functions_index[indices[i][1]]]
		local algo = algorithms_list[algorithms_index[indices[i][2]]]
		if fun and algo then
			self.functions_indexing[fun.name] = self.functions_indexing[fun.name] or {}
			self.noise_indexing[fun.noisename] = self.noise_indexing[fun.noisename] or {}
			self.scale_indexing[fun.scalename] = self.scale_indexing[fun.scalename] or {}
			self.functions_indexing[fun.name][fun:hash()] = true
			self.noise_indexing[fun.noisename][fun:hash()] = true
			self.scale_indexing[fun.scalename][fun:hash()] = true

			self.algorithms_indexing[algo.name] = self.algorithms_indexing[algo.name] or {}
			self.algorithms_indexing[algo.name][algo:hash()] = true

			local dim = dims[i]

			local thisxmin

			if dim == 1 then
				thisxmin = xmin[i][1]
			elseif dim > 1 then
				thisxmin = xmin[{{i}, {1, dim}}]
			end

			local thisfmin = fmin[i]

			local repet = repets[i]

			local thifmins = nil

			if repet > 0 then
				thisfmins = fmins[{{i}, {1, repet}}]:squeeze()
			end

			local exp = optimbench.experiment_entry(algo, fun, self.repetitions, self.steps)

			exp.fmin = thisfmin
			exp.xmin = thisxmin
			exp.fmins = thisfmins

			self.experiments[algo:hash()] = self.experiments[algo:hash()] or {}

			self.experiments[algo:hash()][fun:hash()] = exp
		end
	end

end

--[[ This function adds a new algorithm in the database in order to benchmark it. 
Parameters:
 * `algoname` - the name of the algorithm
 * `algofun` - the function that implements the algorithm
 * `opt` - a table with the parameter configuration of the algorithm

Example:
 exp:addAlgorithm('sgd', optim.sgd, {learningRate})
]]--
function experiments_db:addAlgorithm(algoname, algofun, opt)

	local options = table.copy(opt)
	self.experiments = self.experiments or {}
	self.algorithms_indexing[algoname] = {}
	for k, v in pairs(options) do
		if type(k) == 'number' then
			options[v] = parameters[v] or {}
			options[k] = nil
		else
			options[k] = v or parameters[k] or {}
		end
	end
	for k, v in pairs(computeVariants(algoname, {options})) do
		v.name = nil
		v.fun = nil
		local alg = optimx.benchmarking.algo(algoname, algofun, v)
		local alg_hash = alg:hash()
		algorithms_list[alg_hash] = alg

		self.experiments[alg_hash] = {}
		self.algorithms_indexing[algoname][alg_hash] = true

		for kf, v in pairs(self.referenceExperiments) do
			self.experiments[alg_hash][kf] = optimx.benchmarking.experiment_entry(alg, v.fun, self.repetitions, self.steps)
		end
	end
end

--[[ This function runs all the experiments assosicated with an algorithm. ]]--
function experiments_db:testAlgorithm(algoname)
	if self.experiments[algoname] ~= nil then
		for _, exp in pairs(self.experiments[algoname]) do
			exp:run()
		end
	elseif self.algorithms_indexing[algoname] ~= nil then
		for ka, _ in pairs(self.algorithms_indexing[algoname]) do
			for _, exp in pairs(self.experiments[ka]) do
				print(exp.fun:hash(), exp.algo:hash())
				exp:run()
			end
		end
	else
		print('Algorithm ', algoname, ' not in DB')
		return 
	end
end



