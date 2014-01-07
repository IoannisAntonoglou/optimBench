--[[ This file defines some univariate function prototypes
]]--
require 'torch'
--require 'torchExtensions'

local prototypes={}

--[[ This function generates a line prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of a line prototype.
]]--
function prototypes.LineGenerator(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime

	local wfun = function(x)
		local f = (x-xs) * fprime + fs
		local g = fprime
		return f, g
	end
	return wfun
end

--[[ This function generates a linear rectifier prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of a linear rectifier prototype.
]]--
function prototypes.ReluGenerator(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	local l2 = fprime * fprime

	local xm = (xe+xs*math.sqrt(1+l2))/(1+math.sqrt(1+l2))
	local fm = fprime*(xm-xs)+fs

	local wfun = function(x)
		local f, g
		if x > xm then
			f = fm
			g = 0
		else
			f = (x-xs)*fprime+fs
			g = fprime
		end
		return f, g
	end
	return wfun
end

--[[ This function generates an angle prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point
 * `angle` - the value of the angle in degrees

Returns an instance of an angle prototype.
]]--
local function angleGenerator(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	opt.angle = opt.angle or 90
	local angle = opt.angle
	local ls = fprime
	local le
	angle = angle * math.pi/180

	if opt.angle == 90 then
		le = -1/ls
	else
		local tanf = math.tan(angle)
		le = (ls - tanf)/(1 + ls*tanf)
	end
	local gamma = math.sqrt((1+ls*ls)/(1+le*le))
	local xm = (gamma*xs + xe)/(1+gamma)
	local fm = ls * (xm-xs)+fs
	local fe = le*(xe-xm) + fm

	local wfun = function(x)
		local f, g
		if x > xm then
			f = (x-xm)*le + fm
			g = le
		elseif x < xm then
			f = (x-xs)*ls + fs
			g = ls
		else
			f = fm
			g = 0
		end
		return f, g
	end
	return wfun
end

--[[ This function generates an absolute value prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of an absolute value prototype.
]]--
function prototypes.AbsGenerator(opt)
	local fprime = opt.fprime
	local thetas = math.atan(fprime)*180/math.pi
	local angle = 2*thetas - 180
	opt.angle = angle
	return angleGenerator(opt)
end

--[[ This function generates a bend prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of a bend prototype.
]]--
function prototypes.BendGenerator(opt)
	-- assert(opt.fprime==0, 'Error the gradient before a bend has to be 0')
	if (opt.oldfprime) and opt.fprime~=0 then 
		error('Error the gradient before a bend has to be 0')
	end
	local defaultAngle = -45*math.pi/180
	local sign = opt.sign or 1
	local fprime_e = opt.oldfprime or opt.fprime or math.tan(defaultAngle)
	fprime_e = fprime_e*sign
	opt.angle = 180 - math.atan(fprime_e)*180/math.pi
	opt.fprime = 0
	return angleGenerator(opt)
end

--[[ This function generates a cliff prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of a cliff prototype.
]]--
function prototypes.CliffGenerator(opt)
	assert(opt.fprime ~= 0, 'Error the gradient before the cliff cannot be 0')
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	local sign = opt.sign or -1
	local steepness = sign*10

	local ls = fprime
	local le = fprime*steepness
	local theta_s = math.atan(ls)
	local theta_e = math.atan(le)
	local angle = theta_s - theta_e
	angle = angle * 180/math.pi
	opt.angle = angle
	return angleGenerator(opt)
end

--[[ This function generates a ridge prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of a cliff prototype.
]]--
function prototypes.RidgeGenerator(opt)
	assert(opt.fprime ~= 0, 'Error the gradient before the ridge cannot be 0')
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	local sign = opt.sign or 1
	local steepness = sign*10

	local ls = fprime
	local le = fprime*steepness
	local theta_s = math.atan(ls)
	local theta_e = math.atan(le)
	local angle = theta_s - theta_e
	angle = angle * 180/math.pi
	opt.angle = angle
	return angleGenerator(opt)
end

--[[ This function generates an exponential prototype.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of an exponential prototype.
]]--
function prototypes.ExponGenerator(opt)
	local xs = opt.xs 
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime

	local b = math.log(1000)/(xe-xs)
	local a = -fprime*math.exp(b*xs)/b
	local c = fs - a*math.exp(-b*xs)

	local wfun = function (x)
		local f, g
		f = math.exp(-b*x)
		g = -a*b*f
		f = a*f+c
		return f, g
	end

	return wfun
end

--[[ This function generates a prototype, which is the convex part of a quadratic function.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the convex part of a quadratic function.
]]--
function prototypes.QuadGeneratorConvex(opt)
	local xs = opt.xs 
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime

	--[[
		Assumption the derivative of f at e is 1/10 of the derivative of f at s if fprime negative or 10 times more if fprime positive
	]]--

	local xo

	if fprime > 0 then
		xo = (10*xs-xe)/9
	else
		xo = (xe - 0.1*xs)/0.9
	end

	local a = fprime/(2*(xs-xo))
	local c = fs - a*(xs-xo)*(xs-xo)

	local wfun = function(x)
		local f, g
		f = (x-xo)
		g = 2*a*f
		f = f*f*a+c
		return f, g
	end
	return wfun

end

--[[ This function generates a prototype, which is the bowl part of a quadratic function.

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the bowl part of a quadratic function.
]]--
function prototypes.QuadGeneratorBowl(opt)
	local xs = opt.xs 
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime

	--[[
		Assumption fs == fe
	]]--

	local xo = (xs+xe)/2
	local a = fprime/(2*(xs-xo))
	local c = fs - a*(xs-xo)*(xs-xo)

	local wfun = function(x)
		local f, g
		f = (x-xo)
		g = 2*a*f
		f = f*f*a+c
		return f, g
	end
	return wfun

end

--[[ This function generates a prototype, which is the non-convex part of a gaussian function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the non-convex part of a gaussian function.
]]--
function prototypes.GaussGeneratorNonConvex(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end

	--[[
		Assumption in the non convex case the xs point is 4c points away of the mean, where c is the bandwidth
	]]--

	local c = 2*(xe-xs)/(8 - math.sqrt(2))
	local mu	


	-- Descent case
	if fprime > 0 then
		mu = xe - 4*c
	else
		mu = xs +4*c
	end

	local expon = math.exp(-(xs-mu)*(xs-mu)/(c*c))
	local b = (c*c)*fprime/(2*(xs-mu)*expon)
	local a = fs + b*expon

	local wfun = function(x)
		local f, g
		g = 2*b*((x-mu)/(c*c))
		f = math.exp((x-mu)*(x-mu)/(-c*c))
		g = g*f
		f = a - b*f

		return f, g
	end
	return wfun
end

--[[ This function generates a prototype, which is the convex part of a gaussian function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the convex part of a gaussian function.
]]--
function prototypes.GaussGeneratorConvex(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end

	--[[
		Assumption in the convex case from the point where the second derivative is 0 to the point that is 0.1*c away from the mean
	]]--

	local c = 10*(xe-xs)/(5*math.sqrt(2)-1)
	local mu
	-- Descent case
	if fprime > 0 then
		mu = xs - 0.1*c
	else
		mu = xe + 0.1*c
	end

	local expon = math.exp(-(xs-mu)*(xs-mu)/(c*c))
	local b = (c*c)*fprime/(2*(xs-mu)*expon)
	local a = fs + b*expon

	local wfun = function(x)
		local f, g
		g = 2*b*((x-mu)/(c*c))
		f = math.exp((x-mu)*(x-mu)/(-c*c))
		g = g*f
		f = a - b*f

		return f, g
	end
	return wfun

end

--[[ This function generates a prototype, which is the bowl part of a gaussian function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the bowl part of a gaussian function.
]]--
function prototypes.GaussGeneratorBowl(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end

	--[[
		Assumption in the bowl case the xs=mu-0.1*c, xe=mu+0.1*c
	]]--

	local c = 5*(xe-xs)
	local mu = xs + 0.1*c

	local expon = math.exp(-(xs-mu)*(xs-mu)/(c*c))
	local b = (c*c)*fprime/(2*(xs-mu)*expon)
	local a = fs + b*expon

	local wfun = function(x)
		local f, g
		g = 2*b*((x-mu)/(c*c))
		f = math.exp((x-mu)*(x-mu)/(-c*c))
		g = g*f
		f = a - b*f

		return f, g
	end
	return wfun
end

--[[ This function generates a prototype, which is the non-convex part of a laplace function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the non-convex part of a laplace function.
]]--
function prototypes.LaplaceGeneratorNonConvex(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end
	--[[
		Assumption in the non convex case if fprime<=0 then xs =mu-8*c, xe=mu-c else xs=mu+c, xe=mu+8*c
	]]--

	local c = (xe-xs)/(8-1)
	local mu	

	-- Ascend case
	if fprime > 0 then
		mu = xs - c
	else
		mu = xs + 8*c
	end

	local expon = math.exp(-math.abs(xs-mu)/c)
	local b = c*fprime/(expon * math.sign(xs-mu))
	local a = fs + b*expon

	local wfun = function(x, ff, gg)
		local f, g
		g = math.sign(x-mu) * (b/c)
		f = math.exp(math.abs(x-mu)/(-c))
		g = g*f
		f = a - b*f
		return f, g
	end
	return wfun
end

--[[ This function generates a prototype, which is the convex part of a laplace function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the convex part of a laplace function.
]]--
function prototypes.LaplaceGeneratorConvex(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end
	--[[
		Assumption in the non convex case if fprime<=0 then xs =mu-c, xe=mu-0.1*c else xs=mu+0.1*c, xe=mu+c
	]]--
	local c = (xe-xs)/(1-0.1)
	local mu	

	-- Ascend case
	if fprime > 0 then
		mu = xs - 0.1*c
	else
		mu = xs + 1*c
	end

	local expon = math.exp(-math.abs(xs-mu)/c)
	local b = c*fprime/(expon * math.sign(xs-mu))
	local a = fs + b*expon
	
	local wfun = function(x)
		local f, g
		g = math.sign(x-mu) * (b/c)
		f = math.exp(math.abs(x-mu)/(-c))
		g = g*f
		f = a - b*f
		return f, g
	end

	return wfun
end

--[[ This function generates a prototype, which is the bowl part of a laplace function. 

Parameters:
 * `xs` - start point of the prototype
 * `xe` - end point of the prototype
 * `fs` - value of the function at the start point
 * `fprime` - value of the derivative of the function at the start point

Returns an instance of the bowl part of a laplace function.
]]--
function prototypes.LaplaceGeneratorBowl(opt)
	local xs = opt.xs
	local xe = opt.xe
	local fs = opt.fs
	local fprime = opt.fprime
	if fprime == 0 then
		fprime = -1e-7
	end

	--[[
		Assumption in the bowl case the xs=mu-0.1*c, xe=mu+0.1*c
	]]--

	local c = (xe-xs)/(0.2)
	local mu = xs + 0.1*c
	local expon = math.exp(-math.abs(xs-mu)/c)
	local b = c*fprime/(expon * math.sign(xs-mu))
	local a = fs + b*expon

	local wfun = function(x)
		local f, g
		g = math.sign(x-mu) * (b/c)
		f = math.exp(math.abs(x-mu)/(-c))
		g = g*f
		f = a - b*f
		return f, g
	end

	return wfun
end

--[[ This function concatenates function prototypes in order to produce a complex univariate function.

Parameters:
 * `opt`
 	1. `xs` - start point of the prototype
 	2. `xe` - end point of the prototype
 	3. `fs` - value of the function at the start point
 	4. `fprime` - value of the derivative of the function at the start point
 * `functions` - a table of prototypes to be concatenated.
 * `ascend_descend` - a table which defines for each function whether it is ascended or descended. This option makes sense only for prototypes with discontinuity 
 	in their derivative, for example in the case of a bend this option defines whether after the non differentiable point the derivative will have the same or opposite 
 	sign as before this point.

Returns an instance of the resulting concatenated function.
]]--
function prototypes.FunctionGenerator(opt, functions, ascend_descend)
	
	local prototypes_name = {
	line= prototypes.LineGenerator,
	relu= prototypes.ReluGenerator,
	abs= prototypes.AbsGenerator,
	bend= prototypes.BendGenerator,
	cliff= prototypes.CliffGenerator,
	quad_convex= prototypes.QuadGeneratorConvex,
	quad_bowl= prototypes.QuadGeneratorBowl,
	gauss_nonconvex= prototypes.GaussGeneratorNonConvex,
	gauss_convex= prototypes.GaussGeneratorConvex,
	gauss_bowl= prototypes.GaussGeneratorBowl,
	laplace_nonconvex= prototypes.LaplaceGeneratorNonConvex,
	laplace_convex= prototypes.LaplaceGeneratorConvex,
	laplace_bowl= prototypes.LaplaceGeneratorBowl,
	exponential = prototypes.ExponGenerator,
	ridge = prototypes.RidgeGenerator,

	}

	local sign_prototypes = {
		bend=true, cliff=true, ridge=true
	}
	
	if type(functions) ~= 'table' then
		functions = {functions}
		ascend_descend = {ascend_descend}
	end

	local signs = {}
	local index_ascend_descend = 1
	for i, funname in ipairs(functions) do
		if sign_prototypes[funname] ~= nil then
			if ascend_descend[index_ascend_descend] ~= nil then
				signs[i] = ascend_descend[index_ascend_descend]
			end
			index_ascend_descend = index_ascend_descend + 1
		else
			signs[i] = nil
		end
	end

	opt.xs = opt.xs or -2
	opt.xe = opt.xe or 2
	opt.fs = opt.fs or 2
	opt.fprime = opt.fprime or signs[1]*(1)
	assert(opt.xs < opt.xe, 'Start limit cannot be smaller than end limit')

	local generated_functions = {}
	local funopts
	local fs = opt.fs
	local xs = opt.xs
	local fprime = opt.fprime
	local oldfprime
	local xe = opt.xe
	local dx = (xe-xs)/#functions
	xe = xs + dx
	local limits = {}

	for i, funname in ipairs(functions) do
		local fun = prototypes_name[funname]
		funopts = {}
		funopts.fs = fs
		funopts.xs = xs
		funopts.xe = xe
		funopts.fprime = fprime
		funopts.oldfprime = oldfprime
		if signs[i] then
			local sign
			if signs[i] == 'a' then
				if fprime > 0 then
					sign = 1
				elseif fprime < 0 then
					sign = -1
				elseif oldfprime > 0 then
					sign = 1
				elseif oldfprime < 0 then
					sign = -1
				end
			else
				if fprime > 0 then
					sign = -1
				elseif fprime < 0 then
					sign = 1
				elseif oldfprime > 0 then
					sign = -1
				elseif oldfprime < 0 then
					sign = 1
				end
			end
			funopts.sign = sign
		end
		fun = fun(funopts)
		table.insert(generated_functions, fun)
		table.insert(limits, xs)
		if fprime ~= 0 then
			oldfprime = fprime
		end
		fs, fprime = fun(xe)
		xs = xe
		xe = xs + dx
	end

	table.insert(limits, xe)
	local xs = opt.xs

	local wfun = function(x)
		if x <= xs then
			return generated_functions[1](x)
		end
		if x >= xe then
			return generated_functions[#limits-1](x)
		end
		
		local xe, xs
		xs = limits[1]
		for i=2, #limits do
			xe = limits[i]
			if x >= xs and x < xe then
				return generated_functions[i-1](x)
			end
			xs = xe
		end
		if x~=x then
			return x, x
		end
	end

	return wfun
end

--[[ This function generates a new function which is an offset version of the original function fun by xo. ]]--
function prototypes.OffSet(fun, xo)
	local xOffset = nil
	local wfun = function(x)
		return fun(x-xo)
	end
	return wfun
end

optimBench.function_prototypes = prototypes
