
function pairwisecomparenaive(xgpu, Φ⁺gpu, Φ⁻gpu, Nj, Nx)
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x

    for i = index:stride:Nx
        for J = 1:Nj
            y⁺ = 0;
            y⁻ = 0;
            for j = 1:Nx
                y⁺ += F(xgpu[i, J] - xgpu[j, J]);
                y⁻ += F(xgpu[j, J] - xgpu[i, J]);
            end

            y⁺ /= (Nx - 1);
            y⁻ /= (Nx - 1);

            Φ⁺gpu[i, J] = y⁺
            Φ⁻gpu[i, J] = y⁻
        end
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
    Φ⁺gpu = CuArray(d)
    Φ⁻gpu = CuArray(d)

    kernel = @cuda launch=false pairwisecomparenaive(xgpu, Φ⁺gpu, Φ⁻gpu, Nj, Nx)

    config = launch_configuration(kernel.fun)
    println(config)
    @time begin
        CUDA.@sync begin
            kernel(xgpu, Φ⁺gpu, Φ⁻gpu, Nj, Nx;
            threads=config.threads, blocks=config.blocks)
        end
    end

    Φ⁺ = Array(Φ⁺gpu);
    Φ⁻ = Array(Φ⁻gpu);

    return Φ⁺, Φ⁻

end



# Oregon is about 254806 km², so .5km² cells gives
Nx = 4 * (40000) # number of alternatives
Nj = 30 # number of criteria

Φ⁺,Φ⁻ = speedtestnaive(Nx,Nj);
