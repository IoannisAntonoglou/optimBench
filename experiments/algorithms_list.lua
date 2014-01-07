--[[ This file contains the definition of all the algorithms to be assessed with a set of different parameters for each one of them ]]--
require 'torch'

--[[ A table of different configurations for the algorithms' parameters ]]--
local parameters={
	learningRate= {1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1},
	learningRateDecay= {0.01, 0.1, 0.5, 1},
	momentum= {0.1, 0.5, 0.9, 0.99, 0.999},
	lambda= {1e-4, 1e-3, 1e-2, 1e-1, 0.5},
	alpha= {0.5, 0.75, 1.0},
	decay= {1-1e-4, 1-1e-3, 1-1e-2, 1-1e-1, 1-0.5},
	maxLearningRate= {10, 100, 1000},
	sgdLearningRate= torch.linspace(-10, 0, 34):mul(math.log(10)):exp():totable(),
	epsilon= {1e-6, 1e-3}
}
parameters.stepsize = parameters.learningRate

--[[ A table of all the algorithms to be considered ]]--
local algorithms={
	sgd= {fun='sgd', learningRate=parameters.sgdLearningRate},
	sgd_annealing= {fun='sgd', learningRate=parameters.learningRate, learningRateDecay=parameters.learningRateDecay},
	sgd_momentum= {fun='sgd', learningRate=parameters.learningRate, momentum=parameters.momentum},
	sgd_averaging= {fun='asgd', eta0=parameters.learningRate, lambda=parameters.lambda, alpha=parameters.alpha, t0=0},
	sgd_nesterov= {fun='nesterov', learningRate=parameters.learningRate, momentum=parameters.momentum},
	rmsprop= {fun='rmsprop', learningRate=parameters.learningRate, decay=parameters.decay, maxLearningRate=parameters.maxLearningRate},
	rprop= {fun='rprop', stepsize=parameters.stepsize},
	adagrad= {fun='adagrad', learningRate=parameters.learningRate},
	adadelta= {fun='adadelta', decay=parameters.decay, epsilon=parameters.epsilon},
	cg= {fun='cg'},
	--idbd= {fun='idbd'}
}

local algorithms_list={}

--[[ Help function for generating a shallow copy of a table ]]--
local function copyTable(t)
	local tt= {}
	for k,v in pairs(t) do 
		tt[k] = v
	end
	return tt
end

--[[ This functions generates a list of all possible parameter configurations for an algorithm ]]--
function computeVariants(name, t)

	for k, v in pairs(t) do
		t[k].name = name
		for kk, vv in pairs(v) do
			if type(vv) == 'table' then
				for _, value in pairs(vv) do
					local copy = copyTable(v)
					 copy[kk]=value
					 --copy.name=name
					 table.insert(t, copy)
				end
				t[k]=nil
				break
			end
		end
	end
	return t
end

--[[ This function generates a list of all possible algorithms with all of their possible configurations ]]--
local function generateAlgorithmsList()
	for algo_name, algo_values in pairs(algorithms) do
		for _, algo_variants in pairs(computeVariants(algo_name, {algo_values})) do
			table.insert(algorithms_list, algo_variants)
		end
	end
	-- wrap algorithms around objects
	for i, algorithm in ipairs(algorithms_list) do
		local name = algorithm.name
		local fun = algorithm.fun
		algorithm.name = nil
		algorithm.fun = nil
		local algo=optimx.benchmarking.algo(name, fun, algorithm)
		algorithms_list[algo:hash()] = algo
		algorithms_list[i] = nil
	end
end

generateAlgorithmsList()

optimBench.algorithms_list = algorithms_list
