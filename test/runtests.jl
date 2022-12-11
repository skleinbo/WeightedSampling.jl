using WeightedSampling
using Test

@testset "WeightedSampling.jl" begin
    @test sample(WeightedSampler(rand(10)), 10, ordered=true) == 1:10 
end
