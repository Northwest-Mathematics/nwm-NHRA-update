
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

# warpReduce(sdata, tid) 
# {
#     sdata[tid] += sdata[tid+32];
#     sdata[tid] += data[tid+16];
#     sdata[tid] += sdata[tid+8];
#     sdata[tid] += sdata[tid+4];
#     sdata[tid] += sdata[tid+2];
#     sdata[tid] += sdata[tid+1];

# }


function pairwisecompare2D(xgpu, Φ⁺gpu, Φ⁻gpu, J, Nx, threadsⱼ)
    indexᵢ = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    strideᵢ = gridDim().x * blockDim().x

    indexⱼ = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    strideⱼ = gridDim().y * blockDim().y

    S⁺ = CuStaticSharedArray(Float64, threadsⱼ)
    S⁻ = CuStaticSharedArray(Float64, threadsⱼ)
    local_id = threadIdx().y + 1
    

    for i = indexᵢ:strideᵢ:Nx
        # for j = indexⱼ:strideⱼ:Nx
        #     S⁺[local_id] = F(xgpu[i, J] - xgpu[j, J])
        #     S⁻[local_id] = F(xgpu[j, J] - xgpu[i, J])
        # end

            sync_threads()

            stride = blockDim().y ÷ 2; 
            # while stride > 0
                
            #     @inbounds if threadIdx().y < stride
            #         S⁺[local_id] = S⁺[local_id] + S⁺[local_id + stride];
            #         S⁻[local_id] = S⁻[local_id] + S⁻[local_id + stride];
            #     end

            #     sync_threads();
            #     stride ÷=2
            # end

            # if local_id == 1
            #     CUDA.@atomic Φ⁺gpu[i, J] += S⁺[local_id]
            #     CUDA.@atomic Φ⁻gpu[i, J] += S⁻[local_id]
            # end
            
            # if thread_id < 32
            #     warpReduce(S⁺,local_id);
            #     warpReduce(S⁻,local_id);
            # end
        Φ⁺gpu[i, J] /= (Nx - 1)
        Φ⁻gpu[i, J] /= (Nx - 1)
    end
end