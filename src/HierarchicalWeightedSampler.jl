struct SamplingEvent{N}
    name::Symbol
end
nreactions(::SamplingEvent{N}) where N = N

struct HierarchicalWeightedSampler{T}
    n::Int
    sampler::WeightedSampler{T}
    events::Vector{SamplingEvent}
    nreactions::Int
end
function HierarchicalWeightedSampler(n::Integer, events::Vector{SamplingEvent}, rates::Vector{Float64})
    nr = mapreduce(e->nreactions(e), +, events)
    HierarchicalWeightedSampler(n, WeightedSampler(rates), events, nr)
end
function HierarchicalWeightedSampler(n::Integer, events::Vector{SamplingEvent})
  nr = mapreduce(e->nreactions(e), +, events)
  HierarchicalWeightedSampler(n, events, zeros(n*nr))
end

sample(hws::HierarchicalWeightedSampler) = index_to_event(hws, sample_index(hws))

sample_index(hws::HierarchicalWeightedSampler) = sample(hws.sampler, 1)

function index_to_reaction(hws::HierarchicalWeightedSampler, index)
    i = 0
    thisevent = hws.events[begin].name
    for event in hws.events
        thisevent = event.name
        if i + nreactions(event) < index
            i += nreactions(event)
        else
            break
        end
    end
    j = 1
    while j<index-i
        j += 1
    end
    return (thisevent, j)
end 

function index_to_event(hws::HierarchicalWeightedSampler, index)
    site = ceil(Int, index/hws.nreactions)
    reaction = index_to_reaction(hws, index%hws.nreactions)
    return (site, reaction...)
end