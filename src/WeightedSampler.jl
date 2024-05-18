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

"""
    sample([rng], ws::WeightedSampler, k)

Sample `k` indices without replacement from sampler `ws`.

Optionally specify a random number generator as the first argument.
"""
sample(ws::WeightedSampler, k; ordered=false) = sample(Random.GLOBAL_RNG, ws, k; ordered)
function sample(rng, ws::WeightedSampler, k; ordered=false)
    u = rand(rng) * ws.heap[1]
    i = find_first_larger_node(ws, u)
    if k == 1
        return i
    end
    samples = Vector{Int}(undef, k)
    samples[1] = i
    oldweights = Vector{eltype(ws.heap)}(undef, k)
    oldweights[1] = ws.heap[ws.d+i]
    adjust_weight!(ws, i, 0)
    for j in 2:k
        v = rand(rng) * ws.heap[1]
        x = samples[j] = find_first_larger_node(ws, v)
        oldweights[j] = ws.heap[ws.d+x]
        adjust_weight!(ws, x, 0)
    end
    for x in zip(samples, oldweights)
        adjust_weight!(ws, x...)
    end
    return ordered ? sort(samples) : samples
end

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