 include("kernels.jl")

# simple RELU
function F(x::Float32)::Float32
    if x <= 0 
        return 0.0f0
    elseif x < 1.0f0
        return x
    else
        return 1.0f0
    end
end

function speedtestnaive(Nx, Nj)
    x = rand(Float32, Nx, Nj)
    d = zeros(Float32, Nx, Nj)

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

Φ⁺,Φ⁻ = speedtestnaive(4 * (254806) , 1);
