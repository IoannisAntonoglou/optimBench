--[[ This file includes some useful utility functions.
Some of them have been added to the torch.Tensor class to make calling them easier.
]]--

require 'torch'

--[[ Utility function for taking each element to a different power, as provided in the second tensor. ]]--
function torch.Tensor.powers(t, exps)
	return (torch.log(t):cmul(exps)):exp()
end

--[[ Utility function for computing the logarithm with base 10 of a Tensor ]]--
function torch.Tensor.log10(t)
	return torch.log(t)/torch.log(10)
end

--[[ Utility function that returns the sign of the elements of a Tensor and 0 for 0 elements ]]--
function torch.Tensor.sign(t)
	return torch.sign(t)
end

--[[ Utility function that computes the median value in a Tensor ]]--
function torch.Tensor.median(t)
	if t:nDimension() ~= 1 then
		error('Tensor has to have dimension 1')
	end
	local dim = t:nElement()
	local st = torch.sort(t)
	if dim % 2 == 0 then
		return (st[dim/2]+st[dim/2+1])/2.0
	else
		return st[(dim+1)/2]
	end
end

--[[ Utility function that computes the number of all the elements in a table and not only the number indexed ones ]]--
function table.size(t)
	local s =0 
	for _, _ in pairs(t) do s = s+1 end
	return s
end

--[[ Utility function that creates a deep copy of a table recursively ]]--
function table.copy(t)
	local newtable = {}
	for k, v in pairs(t) do
		if type(v) == 'table' then
			newtable[k] = table.copy(v)
		else
			newtable[k] = v
		end
	end
	return newtable
end

--[[ Utility function that returns a list with all the keys of a table ]]--
function table.keys(t)
	local keys = {}
	for k, _ in pairs(t) do table.insert(keys, k) end
	return keys
end

--[[ Utility function that returns a new sorted copy of the provided table ]]--
function table.sortByValue(t)
	local vals = {}
	local i=1
	for k, v in pairs(t) do
		vals[i] = {k, v}
		i=i+1
	end

	table.sort(vals, function(a, b) return a[2] < b[2] end)

	local sorted = {}

	for k, v in pairs(vals) do
		table.insert(sorted, v[1])
	end
	return sorted
end

--[[ Utility function that splits a string into a list of strings according to the seperators provided in pat ]]--
function string.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

