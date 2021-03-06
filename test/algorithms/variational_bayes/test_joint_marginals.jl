module JointMarginalsTest

using Test
using ForneyLab

import ForneyLab: generateId, addNode!, associate!, inferMarginalRule, isApplicable, Cluster, Product

# Integration helper
mutable struct MockNode <: FactorNode
    id::Symbol
    interfaces::Vector{Interface}
    i::Dict{Int,Interface}

    function MockNode(vars::Vector{Variable}; id=generateId(MockNode))
        n_interfaces = length(vars)
        self = new(id, Vector{Interface}(undef, n_interfaces), Dict{Int,Interface}())
        addNode!(currentGraph(), self)

        for idx = 1:n_interfaces
            self.i[idx] = self.interfaces[idx] = associate!(Interface(self), vars[idx])
        end

        return self
    end
end

@marginalRule(:node_type     => MockNode,
              :inbound_types => (Message{PointMass}, Message{PointMass}, ProbabilityDistribution),
              :name          => MMockPPD)

@testset "@marginalRule" begin
    @test MMockPPD <: MarginalRule{MockNode}
    @test isApplicable(MMockPPD, [Message{PointMass}, Message{PointMass}, ProbabilityDistribution])
    @test !isApplicable(MMockPPD, [Message{PointMass}, Message{PointMass}, ProbabilityDistribution, ProbabilityDistribution])    
end

@testset "inferMarginalRule" begin
    FactorGraph()
    nd = MockNode([constant(0.0), constant(0.0), constant(0.0)])
    cluster = Cluster(nd, [nd.i[1].edge, nd.i[2].edge])

    @test inferMarginalRule(cluster, [Message{PointMass}, Message{PointMass}, ProbabilityDistribution]) == MMockPPD
end

@structuredVariationalRule(:node_type     => MockNode,
                           :outbound_type => Message{PointMass},
                           :inbound_types => (Nothing, Message{PointMass}, ProbabilityDistribution),
                           :name          => SVBMock1VGD)

@structuredVariationalRule(:node_type     => MockNode,
                           :outbound_type => Message{PointMass},
                           :inbound_types => (Message{PointMass}, Nothing, ProbabilityDistribution),
                           :name          => SVBMock2GVD)

@testset "marginalTable" begin
    FactorGraph()
    v1 = constant(0.0)
    v2 = constant(0.0)
    v3 = constant(0.0)
    nd = MockNode([v1, v2, v3])

    InferenceAlgorithm()
    rf_12 = PosteriorFactor([v1, v2])

    rf_12.schedule = variationalSchedule(rf_12)
    marginal_table = marginalTable(rf_12)

    @test length(marginal_table) == 1
    @test marginal_table[1].target == first(rf_12.clusters)
    @test marginal_table[1].interfaces[1] == nd.i[1].partner
    @test marginal_table[1].interfaces[2] == nd.i[2].partner
    @test marginal_table[1].marginal_update_rule == MMockPPD
end

end # module