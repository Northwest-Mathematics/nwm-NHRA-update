# © 2024 Northwest Mathematics <consulting@northwestmath.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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