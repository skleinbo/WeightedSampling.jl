module WeightedSampling

export WeightedSampler, HierarchicalWeightedSampler, adjust_weight!, sample, weight

import Random

include("WeightedSampler.jl")
include("HierarchicalWeightedSampler.jl")

end # MODULE
