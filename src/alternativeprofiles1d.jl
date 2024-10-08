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

function alternativeprofiles1D(Nx, Nj)
    x = rand(Float32, Nx, Nj)
    d = zeros(Float32, Nx, Nj)

    # weights
    w = Float64.(rand(1:5, Nj))
    w ./= sum(w)   

    xgpu = CuArray(x)
    Φ⁺gpu = CuArray(d)
    Φ⁻gpu = CuArray(d)

    kernel = @cuda launch=false pairwisecompare1D(xgpu, Φ⁺gpu, Φ⁻gpu, Nj, Nx)

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

# Φ⁺,Φ⁻ = alternativeprofiles1D(4 * (254806) , 30);
