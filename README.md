OptimBench
----------------------

Description of repository
----------------------
This repository implements a framework for evaluating optimisation gradient based algorithms (implemented in lua-torch) under a set of unit-tesrt functions.
It provides with all the necessary tools for easily storing, accessing and plotting all the computed results. It also simplifies the task of creating new 
unit-test functions by using a simple descriptive language. 


Installation
---------------------------
$ git clone git@github.com:IoannisAntonoglou/optimBench.git
$ luarocks make 


Quick Start
---------------------------
It simple to test all the algorithms implemented in optim for all the predefined set of functions (these are defined in experiments/function_definitions.lua) using the following code:

	require 'optimbench' 
	experiment = optimbench.experimentsDB()
	experiment:runExperiments()
	experiment:save('allResults')

It is easy to assess the performance of the optimisation algorithms based on the results computed, using the following code:
	experiment = optimBench.experimentsDB()
	experiment:load('allResults')
	experiment:ComputeReferenceValues()
	experiment:assessPerformance()

A plot of the performance of a specific optimisation algorithm for all the possible configurations of its parameters can be produced as follows:
	experiment:plotExperiments({}, {algoname})

where algoname is the name of the algorithm, for example 'sgd_annealing'.

Define new unit-test functions
----------------------------
You can define new unit-test functions and add them in the experiments/functions_definitions.lua file. The template for the definition of new 
prototype functions is the following:

 {functionname}_{noiseList}_{scaleList}_{normList}_{rotationList}_{curlList}

 * functionname - The convention for deterministic functions is the following:
  - For each dimension the univariate function prototypes to be concatenated are separated by the - symbol. 
  - At the end of each univariate function definition there is a number that defines in how many dimensions this prototype should be repeated. This number is 
  surrounded by the | symbol. For example, the name quad_convex-quad_bowl-quad_convex|2| defines that a univariate function which is the concatenation os quad_convex
  prototype, a quad_bowl prototype and a quad_convex prototype shall be repeated for the next 2 dimensions. 
  - Example of functioname: abs|1|quad_bowl|9|, that means that the first dimension is a abs function and the remaining 9 a quad_bowl

 * noiseList - The convention for the noise is the following:
  For each dimension a list of noise prototypes is being defined. This list could be either separated by commas or it could be a * symbol. The * symbol 
  matches everything and it can be combined with a prefix to define a list of noises. For example, the gauss_add* defines a list of all possible additive 
  gaussian noises and it is equivalent to gauss_add_normal,gauss_add_high. At the end of each noise definition there is a number surrounded by the | symbol that 
  defines in how many dimensions this list of noises shall be applied. 

 * scaleList - The convention for the scale is the following:
  For each dimension a list of scale prototypes is being defined. This list could be either separated by commas or it could be a * symbol. The * symbol 
  matches everything. At the end of each noise definition there is a number surrounded by the | symbol that defines in how many dimensions this list of 
  scales shall be applied. 

 * normList - A list of different norms to combine all the different univariate functions. 

 * rotationList - A list that defines whether the multivariate function shall be rotated or not. 

 * curlList - A list that defines whether the gradient of the multivariate function shall be curled or not. 
 
 * nonStationarityList - A list that defines whether there is non-stationarity in the function