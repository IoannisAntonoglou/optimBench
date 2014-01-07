require 'torch'
require 'torchffi'

--[[ Utility function that computes the sign of a number ]]--
function math.sign(x)
	if x>0 then
		return 1
	elseif x<0 then
		return -1
	end
	return 0
end

--[[ Utility function that computes a random orthogonal projection matrix of dimension dim ]]--
function torch.orth(dim)
	assert(dim>0, '0x0 orthogonal matrix cannot be defined')
	local a = torch.randn(dim, dim)
	local u, s, v = torch.svd(a)
	return u
end

--[[ This is a utility function that finds the elements in a tensor within an interval

Parameters:
 * `t` - the Tensor
 * `a` - the low endpoint
 * `b` - the high endpoint

Returns:
A ByteTensor with value 1 in the indices that correspond to Tensor values within the interval [a, b] and 0 everywhere else.

--]]
function torch.Tensor.between(t, a, b)
	if a == nil then
		return t:le(b)
	end
	if b == nil then
		return t:ge(a)
	end
	assert(b>a, 'The limit b should be greater than a, example t:between(-2, 3)')
	local MoreThanA = t:ge(a)
	local LessThanB = t:le(b)
	return MoreThanA:eq(LessThanB)
end
--[[ This utility function creates a table with the same values as the Tensor provided
]]--
function torch.Tensor.totable(t)
	local tt = {}
	if t:nDimension()==0 then
		return tt
	end
	for i=1, t:size(1) do
		tt[i] = t[i]
	end
	return tt
end


torch.Tensor.old_randn = torch.Tensor.randn
--[[ Utility function that fills a Tensor with random values sampled from a Gaussian with mean 0 and std 1 ]]--
function torch.Tensor.randn(self, args, ...)
	if not args then
		local size = self:size()
		self:old_randn(size)
		return self
	else
		return self:old_randn(args, ...)
	end
end

