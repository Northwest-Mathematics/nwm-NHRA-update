
function pairwisecomparenaive(xgpu, dgpu, J, Nx)
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x

    for i = index:stride:Nx
        y = 0;

        for j = 1:Nx
            y += F(xgpu[i, J] - xgpu[j, J]);
        end

        dgpu[i, J] = y / (Nx - 1);
    end

end

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

function speedtestnaive(Nx, Nj)
    x = rand(Nx, Nj)
    d = zeros(Nx, Nj)

    # weights
    w = Float64.(rand(1:5, Nj))
    w ./= sum(w)   

    xgpu = CuArray(x)
    dgpu = CuArray(d)

    index = 1

    kernel = @cuda launch=false pairwisecomparenaive(xgpu, dgpu, index, Nx)

    config = launch_configuration(kernel.fun)
    println(config)
    for crit = 1:Nj
        CUDA.@sync begin
            kernel(xgpu, dgpu, crit, Nx;
            threads=config.threads, blocks=config.blocks)
        end
    end

    d = Array(dgpu);

    return d

end



# Oregon is about 254806 km², so .5km² cells gives
Nx = 4 * (100000) # number of alternatives
Nj = 30 # number of criteria

@time begin
    Φ⁺ = speedtestnaive(Nx,Nj)
end