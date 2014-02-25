require 'optimbench'


local function sortFuns(db, variants)
	all_variants = {}
	local len = 0
	for k, _ in pairs(variants) do
		if db.referenceExperiments[k] then
			all_variants[k] = db.referenceExperiments[k].algo.config.learningRate
			len = len+1
		end
	end

	local all_variants = table.sortByValue(all_variants)

	return all_variants, len
end

-- Load all results to the DB

local DB = optimbench.experimentsDB()

DB:load('theDB')

DB:ComputeReferenceValues()

DB:assessPerformance()

local fun_blocks = {}

local algo_blocks = {}

local margin = 10

local algos = {}

for ka, _ in pairs(DB.algorithms_indexing) do
	table.insert(algos, ka)
end

table.sort(algos)

--- FUNCTION BLOCKS ---

local funs = {'1D Noiseless', '1D Differentiable', '1D Non-Differentiable', '1D Heavy Noise',
'1D Scale Non-Stationary', '1D Noise Non-Stationary', '1D Offset Non-Stationary',
'2D Separable', '2D Non-Separable', '2D Curled Derivatives',
'10D Separable', '10D Non-Separable', '10D Curled Derivatives'}


local all_funs = {}

for k,v in pairs(DB.functions_indexing) do
	for kk, vv in pairs(v) do
		all_funs[kk] = optimbench.functions_list[kk]
	end
end

local fun_blocks = {}

for _, v in pairs(funs) do
	fun_blocks[v] = {}
end

for k, v in pairs(all_funs) do
	-- 1 Dimensional
	if v.dim == 1 then
		-- 1D Noiseless
		if v.noisename == 'noiseless|1|' and v.non_statname == 'normal' then
			fun_blocks['1D Noiseless'][k] = true
		end
		-- 1D Non-Differentiable

		if (v.name:find('bend') or v.name:find('relu') or 
			v.name:find('abs') or v.name:find('cliff') or 
			v.name:find('ridge') or v.name:find('laplace_bowl') ) and v.non_statname == 'normal' then
			fun_blocks['1D Non-Differentiable'][k] = true
		elseif v.non_statname=='normal' then
			fun_blocks['1D Differentiable'][k] = true
		end

		if v.noisename:find('high') and v.non_statname == 'normal' then
			fun_blocks['1D Heavy Noise'][k] = true
		end

		if v.non_statname == 'scale' and v.noisename == 'noiseless|1|' then
			fun_blocks['1D Scale Non-Stationary'][k] = true
		elseif v.non_statname == 'offset' and v.noisename == 'noiseless|1|' then
			fun_blocks['1D Offset Non-Stationary'][k] = true
		elseif v.non_statname == 'noise' and (not (v.noisename:find('high'))) then
			fun_blocks['1D Noise Non-Stationary'][k] = true
		end
	elseif v.dim == 2 then
	-- 2 Dimensional 
		if not v.rotated then
			fun_blocks['2D Separable'][k] = true
		elseif v.rotated == true then
			fun_blocks['2D Non-Separable'][k] = true
		end
		if v.curled == true then
			fun_blocks['2D Curled Derivatives'][k] = true
		end
	elseif v.dim == 10 then
		-- 10 Dimensional 
		if not v.rotated then
			fun_blocks['10D Separable'][k] = true
		elseif v.rotated == true then
			fun_blocks['10D Non-Separable'][k] = true
		end
		if v.curled == true then
			fun_blocks['10D Curled Derivatives'][k] = true
		end
	end
end


local ydim = 0
local len
for _, fun in pairs(funs) do
	fun_blocks[fun], len = sortFuns(DB, fun_blocks[fun])
	if len then
		ydim = ydim + len + margin
	end
end

local xdim = 0

for _, algo in pairs(algos) do
	algo_blocks[algo], len = DB:_DBsortAlgos(algo)
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
				r, g, b = unpack(DB.experiments[a][f].colour)
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

DB:_nicePlot(funs, algos, blocks, data)
