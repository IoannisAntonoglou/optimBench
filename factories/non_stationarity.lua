--[[ Some functions for simulating the non-stationarity observed in real life problems ]]--

require 'torch'
--require 'torchExtensions'

local non_stationarity= {}

--[[ This function simulates the case of abrupt changes in the shape of an error surface. It takes a list of functions as its first argument and it returns 
a new function that switches between these functions in a circular manner. The number of steps between the switchings is defined by the second argument `stepsize`.
For example if the stepsize is equal to 2, the funs list contains the functions fun1 and fun2, and the new function is called 6 times, then the value for the first 
2 points will be computed using fun1, for the next using fun2 and the last 2 using fun1 again. 

Parameters:
 * `funs` - a list of functions
 * `stepsize` - the number of steps between function switchings

Returns:
A function that exhibits an abrupt switching behaviour

--]]
function non_stationarity.abrupt_switching(funs, stepsize)

	assert(type(funs)=='table', 'Error a table with funs to switch between has not been provided')
	assert(#funs > 1, 'Error at least 2 functions to switch between should be provided')

	stepsize = stepsize or 10

	assert(stepsize>0, 'Error stepsize cannot have a zero or negative value')

	local num_functions = #funs

	local current_fun = 1

	local steps = 0

	local wfun = function(x)
		local f, g = funs[current_fun](x)
		steps = steps + 1
		if steps == stepsize then
			steps = 0
			current_fun = current_fun + 1
			if current_fun > num_functions then
				current_fun = 1
			end
		end
	end

	return wfun
end

--[[ This functions generates a new function that simulates the case where the minimum is constantly moving randomly or towards a predefined direction.

Parameters:
 * `fun` - the original function
 * `opt` - a list of options
 	* `direction` - a deterministic direction towards which the function's minimum is being moved 
 	* `randomness` - a number between 0 and 1 that controls the randomness in the movement of the minimum
Returns:
A function where it's minimum is constantly moving

--]]
function non_stationarity.moving_target(fun, opt)
	local direction = opt.direction
	local randomness
	if not direction then
		randomness = 1.0
		direction = 0
	else
		randomness = opt.randomness or 0.5
	end

	local global_offset = 0

	local wfun = function(x)
		if type(x) == 'number' then
			local global_offset = global_offset + (1-randomness)*direction + randomness * torch.randn(1)[1]
			return fun(x+global_offset)
		else
			if type(global_offset) == 'number' then
				global_offset = x:clone():fill(0)
			end
			global_offset:add(torch.add(torch.mul(direction, 1-randomness), torch.randn(x:size()):mul(randomness)))
			return fun(x:add(global_offset))
		end
	end
	return wfun
end

--[[ Test function for checking the correctness of non stationarity functions above ]]--
function non_stationarity.testFunction(fun, speed)
	local prototypes = require 'prototypes_functions'
	
	local fun1 = prototypes.FunctionGenerator({xs=-2, xe=2, fs=1, fprime=-1}, {'quad_bowl'})

	local fun = non_stationarity.moving_target(fun1, {speed=speed, direction=-1, randomness=1.0})

	local x = torch.linspace(-2, 2)

	local y, _ = fun(x)

	require 'gnuplot'

	gnuplot.plot(x, y)
end

optimbench.non_stationarity = non_stationarity
