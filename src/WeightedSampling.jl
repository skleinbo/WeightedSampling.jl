module WeightedSampling

export WeightedSampler, adjust_weight!, sample, sample_heap, weight

import Base: length

import Random

struct WeightedSampler{T}
    heap::Vector{T}
    d::Int
    n::Int
    function WeightedSampler(v::Vector{T}) where {T}
        n = length(v)
        maxlevel = ceil(Int, log2(n))
        d = 2^maxlevel - 1
        heap = zeros(T, d + 2^maxlevel)
        heap[d+1:d+n] .= v
        i = 1
        for i in d:-1:1
            heap[i] = heap[2i] + heap[2i+1]
        end

        new{eltype(v)}(heap, d, n)
    end
end

length(ws::WeightedSampler) = ws.n

"""
    sample([rng], ws::WeightedSampler, k)

Sample `k` indices without replacement from sampler `ws`.

Optionally specify a random number generator as the first argument.
"""
sample_heap(ws::WeightedSampler, k; ordered=false) = sample(Random.GLOBAL_RNG, ws, k; ordered)
function sample_heap(rng, ws::WeightedSampler, k::T; kwargs...) where T<:Integer
    if k==0
        return T[]
    end
    if k>length(ws)
        throw(ArgumentError("Cannot sample $k out of $(length(ws)) elements without replacement."))
    end
    x = Vector{T}(undef, k)
    sample_heap!(rng, ws, x; kwargs...)
end
sample_heap(rng, wv::AbstractVector, args...; kwargs...) = sample_heap(rng, WeightedSampler(wv), args...; kwargs...)

const sample = sample_heap

function sample_heap!(rng, ws::WeightedSampler, x::AbstractArray; ordered=false, replace=false)
    u = rand(rng) * ws.heap[1]
    i = find_first_larger_node(ws, u)
    k = length(x)
    x[1] = i
    if k == 1
        return x
    end
    if !replace 
        oldweights = Vector{eltype(ws.heap)}(undef, k)
        oldweights[1] = ws.heap[ws.d+i]
        adjust_weight!(ws, i, 0)
    end
    for j in 2:k
        v = rand(rng) * ws.heap[1]
        v = x[j] = find_first_larger_node(ws, v)
        if !replace
            oldweights[j] = ws.heap[ws.d+v]
            adjust_weight!(ws, v, 0)
        end
    end
    if !replace
        for v in zip(x, oldweights)
            adjust_weight!(ws, v...)
        end
    end
    return ordered ? sort!(x) : x
end
sample_heap!(rng, wv::AbstractVector, args...; kwargs...) = sample_heap!(rng, WeightedSampler(wv), args...; kwargs...)
sample_heap!(args...; kwargs...) = sample_heap!(Random.GLOBAL_RNG, args...; kwargs...)

weight(ws::WeightedSampler, j) = ws.heap[ws.d+j]

function adjust_weight!(ws::WeightedSampler, j, w)
    d = ws.d
    idx = d + j
    ws.heap[idx] = w
    parent = idx ÷ 2
    while parent >= 1
        # take the sum of children here;
        # DON't do "-= wold - w" bc. fp errors accum.
        ws.heap[parent] = ws.heap[2parent] + ws.heap[2parent+1]
        parent = parent ÷ 2
    end
end

function find_first_larger_node(ws::WeightedSampler, val)
    d = ws.d
    heap = ws.heap
    i = 1
    while i <= d
        i *= 2
        if val > heap[i] # go right
            val -= heap[i]
            i += 1
        end
    end
    return i - d
end

end # MODULE
