--[[ This file contains functions for combining univariate functions into multivariate ones
]]--

require 'torch'

local multidimensional = {}

--[[ This method combines m univariate functions into one multivariate, by taking the L2 norm:
$${ F(x_1, x_2, ..., x_m)=\sqrt{\sum_{i=1}^{m} F_i(x_i)^2} }$$

where ${F_i}$ is the ${i_th}$ univariate function applied in the ${i_th}$ dimension.

Parameters:
 * `funs` - a list of univariate functions

Returns a multivariate function
]]--
function multidimensional.L2norm(funs)
	local num_funs = #funs
	local wfun = function(x)
		local f, g
		g = x:clone()
		f = 0
		for i, fun in ipairs(funs) do
			local fi, gi = fun(x[i])
			f = f + fi*fi
			g[i] = fi*gi
		end
		f = math.sqrt(f)
		g:div(f)
		return f, g
	end
	return wfun
end

--[[ This method combines m univariate functions into one multivariate, by taking the L1 norm:
$${ F(x_1, x_2, ..., x_m)=\sum_{i=1}^{m}|F_i(x_i)|}$$

where ${F_i}$ is the ${i_th}$ univariate function applied in the ${i_th}$ dimension.

Parameters:
 * `funs` - a list of univariate functions

Returns a multivariate function
]]--
function multidimensional.L1norm(funs)

	local num_funs = #funs
	local wfun = function(x)
		local f, g
		g = x:clone()
		f = 0
		for i, fun in ipairs(funs) do
			local fi, gi = fun(x[i])
			f = f+math.abs(fi)
			g[i] = math.sign(fi) * gi
		end
		return f, g
	end
	return wfun

end

--[[ This method combines m univariate functions into one multivariate, by taking the L2 norm:
$${ F(x_1, x_2, ..., x_m)=\max{\{|F_1|, |F_2|, ..., |F_m|\} }}$$

where ${F_i}$ is the ${i_th}$ univariate function applied in the ${i_th}$ dimension.

Parameters:
 * `funs` - a list of univariate functions

Returns a multivariate function
]]--
function multidimensional.LInfnorm(funs)

	local num_funs = #funs
	local wfun = function(x)
		local f, g
		g = x:clone():fill(0)
		f = 0
		local max_index=1
		for i, fun in ipairs(funs) do
			local fi, gi = fun(x[i])
			fi = math.abs(fi)
			if fi > f then
				f = fi
				max_index = i
			end
		end
		g[max_index] = 1
		return f, g
	end

	return wfun
end

--[[ This method rotates a multivariate function by multiplying the input with an orthonormal rotatation matrix.

Parameters:
 * `fun` - the multivariate function to be rotated
 * `dim` - the dimensionality of the function
 * `rot_seed` - a random seed for the generation of the rotatation matrix
 * `rotationMatrix_` - optionally a pre-existing rotation matrix can be used

Returns a rotated version of the original multivariate function
]]--
function multidimensional.Rotation(fun, dim, rot_seed, rotationMatrix_)
	local rotationMatrix = nil

	if not rotationMatrix_ then
		if rot_seed then
			torch.manualSeed(rot_seed)
			rotationMatrix = torch.orth(dim)
		else
			rotationMatrix = torch.orth(dim)
		end
	else
		rotationMatrix = rotationMatrix_
	end
	
	local wfun = function(x)
		local xx = rotationMatrix*x
		local f, g = fun(xx)
		g = rotationMatrix*g
		return f, g
	end
	return wfun, rotationMatrix
end

--[[ This method transforms the gradient field of a multivariate function into a non-conservative vector field (with non-zero curl).

Parameters:
 * `fun` - the multivariate function to be curled
 * `dim` - the scale of the curl
 * `rot_seed` - a random seed for the generation of the curl matrix

Returns a curled version of the original multivariate function
]]--
function multidimensional.Curl(fun, scale, rot_seed)
	scale = scale or 0.1
	local rotationMatrix = nil
	local wfun = function(x)
		local dim = x:size(1)
		if not rotationMatrix then
			if rot_seed then
				local new_seed = torch.random(1,1e6)
				torch.manualSeed(rot_seed)
				rotationMatrix = torch.orth(dim)
				torch.manualSeed(new_seed)
			else
				rotationMatrix = torch.orth(dim)
			end
		end
		local f, g = fun(x)
		g:add(scale, rotationMatrix*x)
		return f, g
	end
	return wfun
end

--[[ This method offsets a multivariate function by a vector.

Parameters:
 * `fun` - the multivariate function to be offset 
 * `vector` - the vector that offests the multivariate function

Returns an offset version of the original version
]]--
function multidimensional.OffSet(fun, vector)
	local myvector = vector:clone():mul(-1)
	local wfun = function(x)
		return fun(x:add(myvector))
	end
	return wfun
end

optimBench.multivariate_functions = multidimensional