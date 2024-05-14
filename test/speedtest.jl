 include("kernels.jl")

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
# Nx = number of alternatives
# Nj = number of criteria

function speedtest2D(Nx, Nj)
    x = rand(Nx, Nj)
    d = zeros(Nx, Nj)

    # weights
    w = Float64.(rand(1:5, Nj))
    w ./= sum(w)   

    xgpu = CuArray(x)
    Φ⁺gpu = CuArray(d)
    Φ⁻gpu = CuArray(d)

    kernel = @cuda launch=false pairwisecompare2D(xgpu, Φ⁺gpu, Φ⁻gpu, 1, Nx, 16)

    threadsᵢ = 32
    threadsⱼ = 16
    threads = (threadsᵢ, threadsⱼ)
    blocks_i = cld(Nx, threadsᵢ)
    blocks_j = cld(Nx, threadsⱼ)
    blocks = (blocks_i, blocks_j)
    @time begin
        for J = 1:Nj
            CUDA.@sync begin
                kernel(xgpu, Φ⁺gpu, Φ⁻gpu, J, Nx, threadsⱼ;
                    threads=threads, blocks=blocks, shmem =
                    (threadsⱼ * sizeof(Float64)))
            end
        end
    end

    Φ⁺ = Array(Φ⁺gpu);
    Φ⁻ = Array(Φ⁻gpu);

    return Φ⁺, Φ⁻

end

Φ⁺,Φ⁻ = speedtest2D(4 * (1000),30);
Φ⁺,Φ⁻ = speedtestnaive(254806 ,30);
