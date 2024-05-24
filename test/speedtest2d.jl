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

function speedtest2D(Nx, Nj)
    x = rand(Float32, Nx, Nj)
    d = zeros(Float32, Nx, Nj)

    # weights
    w = Float32.(rand(1:5, Nj))
    w ./= sum(w)   

    xgpu = CuArray(x)
    Φ⁺gpu = CuArray(d)
    Φ⁻gpu = CuArray(d)

    kernel = @cuda launch=false pairwisecompare2D(xgpu, Φ⁺gpu, Φ⁻gpu, 1, Nx, 16)

    threadsᵢ = 1
    threadsⱼ = 512
    threads = (threadsᵢ, threadsⱼ)
    blocks_i = cld(Nx, threadsᵢ)
    blocks_j = cld(Nx, threadsⱼ)
    blocks = (blocks_i, blocks_j)
    @time begin
        for J = 1:Nj
            CUDA.@sync begin
                kernel(xgpu, Φ⁺gpu, Φ⁻gpu, J, Nx, threadsⱼ;
                    threads=threads, blocks=blocks, shmem =
                    (threadsⱼ * sizeof(Float32)))
            end
        end
    end

    Φ⁺ = Array(Φ⁺gpu);
    Φ⁻ = Array(Φ⁻gpu);

    return Φ⁺, Φ⁻

end

Φ⁺,Φ⁻ = speedtest2D(4 * (40000), 1);