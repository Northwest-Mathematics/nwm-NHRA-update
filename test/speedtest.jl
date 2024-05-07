# Oregon is about 254806 km², so .5km² cells gives

Nx = 4 * (254806) # number of alternatives
Nj = 30 # number of criteria


x = rand(Nx, Nj)
d = zeros(Nx, Nj)

# simple RELU
function F(x)
    if x <= 0 
        return 0
    elseif x < 1
        return x
    else
        return 1
    end
end

# weights
w = Float64.(rand(1:5, Nj))
w ./= sum(w)   

xgpu = CuArray(x)
dgpu = CuArray(d)

function pairwisecompare(xgpu, dgpu, index)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stridex = gridDim().x * blockDim().x

end

