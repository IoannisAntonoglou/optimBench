--[[ This file defines a set of multivariate prototype functions.
The generation of multivariate functions is based on a name generation scheme. This is a general name convention scheme that can be used for the 
generation of any dimension functions. The name convention has the following template:
 
 {functionname}_{noiseList}_{scaleList}_{normList}_{rotationList}_{curlList}

 * `functionname` - The convention for deterministic functions is the following:
  - For each dimension the univariate function prototypes to be concatenated are separated by the - symbol. 
  - At the end of each univariate function definition there is a number that defines in how many dimensions this prototype should be repeated. This number is 
  surrounded by the | symbol. For example, the name quad_convex-quad_bowl-quad_convex|2| defines that a univariate function which is the concatenation os quad_convex
  prototype, a quad_bowl prototype and a quad_convex prototype shall be repeated for the next 2 dimensions. 
  - Example of functioname: abs|1|quad_bowl|9|, that means that the first dimension is a abs function and the remaining 9 a quad_bowl

 * `noiseList` - The convention for the noise is the following:
  For each dimension a list of noise prototypes is being defined. This list could be either separated by commas or it could be a * symbol. The * symbol 
  matches everything and it can be combined with a prefix to define a list of noises. For example, the gauss_add* defines a list of all possible additive 
  gaussian noises and it is equivalent to gauss_add_normal,gauss_add_high. At the end of each noise definition there is a number surrounded by the | symbol that 
  defines in how many dimensions this list of noises shall be applied. 

 * `scaleList` - The convention for the scale is the following:
  For each dimension a list of scale prototypes is being defined. This list could be either separated by commas or it could be a * symbol. The * symbol 
  matches everything. At the end of each noise definition there is a number surrounded by the | symbol that defines in how many dimensions this list of 
  scales shall be applied. 

 * `normList` - A list of different norms to combine all the different univariate functions. 

 * `rotationList` - A list that defines whether the multivariate function shall be rotated or not. 

 * `curlList` - A list that defines whether the gradient of the multivariate function shall be curled or not. 

]]--

--[[ A table of function definitions based on the name convention described above
]]--
local functions_name={
	'{line|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_bowl|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{abs|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{bend|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{relu|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_bowl|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{cliff|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{ridge|1|}_{*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_convex-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_nonconvex-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_convex-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_convex-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_nonconvex-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_convex-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{line-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-relu|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-relu|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_convex-relu|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_convex-relu|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-gauss_convex-gauss_bowl-gauss_convex-gauss_nonconvex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{laplace_nonconvex-laplace_convex-laplace_bowl-laplace_convex-laplace_nonconvex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{line-quad_bowl-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-abs-quad_convex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-cliff-quad_convex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-cliff-gauss_nonconvex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-quad_bowl-gauss_nonconvex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-abs-gauss_nonconvex|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{cliff-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{cliff-quad_bowl|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-cliff-quad_bowl|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_bowl-cliff-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{relu-bend-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-relu-bend-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-relu-line|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{relu-bend-quad_bowl|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-relu-bend-quad_bowl|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-relu-bend-quad_bowl|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{relu-bend-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_convex-relu-bend-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{gauss_nonconvex-relu-bend-exponential|1|}_{gauss_add*|1|}_{*|1|}_{None}_{normal}_{normal}',
	'{quad_bowl|1|quad_bowl|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{*|2|}_{L1norm}_{rotate,normal}_{normal}',
	'{abs|1|quad_bowl|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal,steep|1|normal|1|,normal|1|steep|1|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{quad_bowl|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|,steep|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{line|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal}_{normal}',
	'{relu|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal}_{normal}',
	'{exponential|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|,steep|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{abs|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|,steep|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{abs|1|abs|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{cliff|1|abs|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|,steep|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{cliff|1|line|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{cliff|1|quad_bowl|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{exponential|1|quad_bowl|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|}_{L1norm}_{normal}_{normal}',
	'{gauss_nonconvex|1|abs|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{saddle|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{gauss_nonconvex|1|quad_bowl|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{saddle|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{laplace_convex-laplace_nonconvex-quad_convex|1|laplace_convex-laplace_nonconvex-quad_convex|1|}_{gauss_add_normal|2|,gauss_add_low|1|gauss_add_high|1|,gauss_add_high|1|gauss_add_low|1|}_{normal|2|,saddle|1|normal|1|}_{L1norm}_{normal}_{normal}',
	'{quad_bowl|10|}_{gauss*|10|}_{*|10|}_{L1norm}_{normal}_{normal}',
	'{laplace_convex-laplace_nonconvex-quad_convex|10|}_{gauss_add*|10|}_{normal|10|,saddle|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{abs|1|quad_bowl|9|}_{gauss_add*|10|}_{normal,normal|1|saddle|9|,normal|1|steep|9|}_{L1norm}_{normal}_{normal}',
	'{quad_bowl|1|line|9|}_{gauss_add*|10|}_{normal,steep|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{line|1|line|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal}_{normal}',
	'{relu|1|line|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal}_{normal}',
	'{exponential|1|line|9|}_{gauss_add*|10|}_{normal|10|,steep|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{abs|1|line|9|}_{gauss_add*|10|}_{normal,steep|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{abs|1|abs|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{cliff|1|abs|9|}_{gauss_add*|10|}_{normal,steep|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{cliff|1|line|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal,rotate}_{normal,curl}',
	'{cliff|1|quad_bowl|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal,rotate}_{normal}',
	'{exponential|1|quad_bowl|9|}_{gauss_add*|10|}_{normal|10|}_{L1norm}_{normal}_{normal}',
	'{gauss_nonconvex|1|abs|9|}_{gauss_add*|10|}_{saddle|1|normal|9|}_{L1norm}_{normal}_{normal}',
	'{gauss_nonconvex|1|quad_bowl|9|}_{gauss_add*|10|}_{saddle|1|normal|9|}_{L1norm}_{normal}_{normal}'
}

--[[ A list of possible noises ]]--
local noises={
	noiseless={},
	gauss_add_low= {'gaussian_additive', 0.01},
	gauss_add_normal = {'gaussian_additive', 0.1},
	gauss_add_high = {'gaussian_additive', 10},
	gauss_mul_low= {'gaussian_multiplicative', 0.1},
	gauss_mul_normal = {'gaussian_multiplicative', 1.0},
	gauss_mul_high = {'gaussian_multiplicative', 10},
	maskout_high= {'maskout', 0.9},
	maskout_low= {'maskout', 0.1},
	cauchy_add_normal= {'cauchy', 1}
}

--[[ A list of possible scales ]]--
local scales={
	normal = {xs = 0, xe = 1, fs = 200, fprime = -1},
	steep = {xs = 0, xe = 1, fs = 200, fprime = -10},
	saddle = {xs =0 , xe = 1, fs = 200, fprime=1},
	flat= {xs=0, xe=1, fs=2, fprime=-0.1}
	}

--[[ A list of possible norms ]]--
local norms={
	L1norm='L1norm',
	L2norm='L2norm',
	LInfnorm='LInfnorm',
}

local rotations={
	rotate=true,
	normal=false
}

local curls={
	curl=true,
	normal=false
}

--[[ Local function for pattern matching ]]--
local function patternMatchingOptions(str, list)
	local options = {}
	if str == '*' then
		for k, v in pairs(list) do 
			table.insert(options, k)
		end
		return options
	end
	local star = str:find('*')
	if star ~= nil then
		for k, v in pairs(list) do
			if k:match(str) then
				table.insert(options, k)
			end
		end
		return options
	end

	if list[str] ~= nil then
		table.insert(options, str)
		return options
	end
	for opt in str:gmatch('%w+') do
		table.insert(options, opt)
	end
	return options
end

--[[ local function for processing a name option ]]--
local function processOption(str, list)
	local variants = string.split(str, ',')
	local all_variants = {}
	for _, variant in pairs(variants) do
		local options_per_dimension = {}
		local repet_per_dimension = {}
		for w in variant:gmatch('(.-)|(.-)|') do
			table.insert(options_per_dimension, w)
		end

		for w in variant:gmatch('|(.-)|') do
			table.insert(repet_per_dimension, tonumber(w))
		end
		
		local options_variants = {}

		for k, option in pairs(options_per_dimension) do
			local expanded_options = {}
			for _, opt in pairs(patternMatchingOptions(option, list)) do
				table.insert(expanded_options, opt..'|'..repet_per_dimension[k]..'|')
			end
			if #options_variants == 0 then
				options_variants = expanded_options
			else
				local new_options_variants = {}
				for _, v in pairs(expanded_options) do
					for _, vv in pairs(options_variants) do
						table.insert(new_options_variants, v..vv)
					end
				end
				options_variants = new_options_variants
			end
		end
		for k, v in pairs(options_variants) do
			table.insert(all_variants, v)
		end

	end

	return all_variants

end


local function processNormRotCurl(str)
	return string.split(str, ',')
end

--[[ Generate a list of distinct function names given the name convention defined above ]]--
local function functionVariantsFromName(name)

	local parts = {}

	for w in name:gmatch('{(.-)}') do
		table.insert(parts, w)
	end

	local funname, noise, scale, norm, rotation, curl = unpack(parts)

	local noise_variants = processOption(noise, noises)
	local scale_variants = processOption(scale, scales)
	local norm_variants = processNormRotCurl(norm)
	local rot_variants = processNormRotCurl(rotation)
	local curl_variants = processNormRotCurl(curl)

	local all_variants = { '{'..funname..'}'}
	local options = {noise_variants, scale_variants, norm_variants, rot_variants, curl_variants}

	for _, opt in pairs(options) do
		local new_all_variants = {}
		for _, case in pairs(opt) do
			for _, variant in pairs(all_variants) do
				table.insert(new_all_variants, variant..'_{'..case..'}')
			end
		end
		all_variants = new_all_variants
	end
	return all_variants
end

--[[ This local function process the name of a deterministic function and it produces a table appropriate for use of the factories.factory constructor.
For example, for the name quad_convex-quad_bowl-quad_convex|1|abs|2| it will produce the table:
{
  1 : 
    {
      1 : "quad_convex"
      2 : "quad_bowl"
      3 : "quad_convex"
    }
  2 : 
    {
      1 : "abs"
    }
  3 : 
    {
      1 : "abs"
    }
}
]]--
local function processFunPerDimension(name)

	local fun_per_dim = {}
	local repet_per_fun = {}

	for w in name:gmatch('(.-)|(.-)|') do
		table.insert(fun_per_dim, w)
	end

	for w in name:gmatch('|(.-)|') do
		table.insert(repet_per_fun, tonumber(w))
	end

	for i, fun_dim in pairs(fun_per_dim) do
		local fun = string.split(fun_dim, '-')
		fun_per_dim[i] = fun
	end

	local fun = {}

	for k, f in pairs(fun_per_dim) do
		for i=1, repet_per_fun[k] do
			table.insert(fun, table.copy(f))
		end
	end

	return fun

end

--[[ This local function process the name of a noise and it produces a table appropriate for use of the factories.factory constructor.
For example, for the noise name gauss_add_normal|1|gauss_mul_normal|2| it will produce the table:
{
  1 : 
    {
      1 : "gaussian_additive"
      2 : 0.1
    }
  2 : 
    {
      1 : "gaussian_multiplicative"
      2 : 0.1
    }
  3 : 
    {
      1 : "gaussian_multiplicative"
      2 : 0.1
    }
}
]]--
local function processNoisePerDimension(name)
	local noise_per_dim = {}
	local repet_per_noise = {}

	for w in name:gmatch('(.-)|(.-)|') do
		table.insert(noise_per_dim, w)
	end

	for w in name:gmatch('|(.-)|') do
		table.insert(repet_per_noise, tonumber(w))
	end

	for i, noise_dim in pairs(noise_per_dim) do
		local noise = noises[noise_dim]
		noise_per_dim[i] = noise
	end

	local noise = {}

	for k, n in pairs(noise_per_dim) do
		for i=1, repet_per_noise[k] do
			table.insert(noise, table.copy(n))
		end
	end

	return noise
end

--[[ This local function process the name of a scale and it produces a table appropriate for use of the factories.factory constructor.
For example, for the scale name normal|1|steep|2| it will produce the table:
{
  fprime : 
    {
      1 : -1
      2 : -10
      3 : -10
    }
  fs : 
    {
      1 : 200
      2 : 200
      3 : 200
    }
  xe : 
    {
      1 : 1
      2 : 1
      3 : 1
    }
  xs : 
    {
      1 : 0
      2 : 0
      3 : 0
    }
}
]]--
local function processScalePerDimension(name)
	local scale_per_dim = {}
	local repet_per_scale = {}

	for w in name:gmatch('(.-)|(.-)|') do
		table.insert(scale_per_dim, w)
	end

	for w in name:gmatch('|(.-)|') do
		table.insert(repet_per_scale, tonumber(w))
	end

	for i, scale_dim in pairs(scale_per_dim) do
		local scale = scales[scale_dim]
		scale_per_dim[i] = scale
	end

	local scale = {}

	for k, s in pairs(scale_per_dim) do
		for i=1, repet_per_scale[k] do
			table.insert(scale, table.copy(s))
		end
	end


	local finalScale = {}
	for k, v in pairs(scale[1]) do
		finalScale[k] = {}
	end

	for _, s in pairs(scale) do
		for k, v in pairs(s) do
			table.insert(finalScale[k], v)
		end
	end

	return finalScale
end


--[[ This local function generates an instance of a function based on the name of the function ]]--
local function generateFunctionFromName(name)

	local parts = {}

	for w in name:gmatch('{(.-)}') do
		table.insert(parts, w)
	end

	local funs, noise, scale, norm, rotation, curl = unpack(parts)
	local funname = funs
	local noisename = noise
	local scalename = scale

	funs = processFunPerDimension(funs)
	noise = processNoisePerDimension(noise)
	scale = processScalePerDimension(scale)

	local fun = optimx.benchmarking.factory({
		name=funname,
		noisename=noisename,
		scalename = scalename,
		funs=funs,
		noise=noise,
		opt=scale,
		norm=norm
		})
	if rotations[rotation] then
		fun:rotate()
	end 

	if curls[curl] then
		fun:curl()
	end
	fun.hashkey = name

	return fun

end

--[[ This function generates all the prototype functions defined in the table functions_name ]]--
function generateMultidimensional()

	local functions = {}

	for _, name in pairs(functions_name) do
		for _, fun in pairs(functionVariantsFromName(name)) do
			functions[fun] = true
		end
	end

	local i=0
	for fun, _ in pairs(functions) do
		functions[fun] = generateFunctionFromName(fun)
		i = i +1
	end
	
	return functions
end

optimBench.functions_list = generateMultidimensional()
