# WeightedSampling.jl

Sum-heap based sampler for efficiently sampling without replacement.

* `WeightedSampler(w)`: Construct a sampler from weight vector `w`.
* `sample(::WeightedSampler, k; ordered=true)`: Sample `k` times without replacement. If `ordered`, sort the output.
* `weight(::WeightedSampler, j)`: weight of the j-th index.
* `adjust_weight!(::WeightedSampler, j, w)`: Set weight of j-th index to `w`.

## Usage

```julia-repl
julia> using WeightedSampling

julia> v = randn(10).^2;

julia> ws = WeightedSampler(v);

julia> sample(ws, 5, ordered=true)
5-element Vector{Int64}:
 2
 4
 5
 6
 8

julia> weight(ws, 3) == v[3]
true

julia> adjust_weight!(ws, 3, 0.0)
```
