    export
ruleSVBGaussianControlledVarianceOutNGDDD,
ruleSVBGaussianControlledVarianceXGNDDD,
ruleSVBGaussianControlledVarianceZDNDD,
ruleSVBGaussianControlledVarianceΚDDND,
ruleSVBGaussianControlledVarianceΩDDDN,
ruleMGaussianControlledVarianceGGDDD,
ruleSVBGaussianControlledVarianceOutNGDD,
ruleSVBGaussianControlledVarianceXGNDD,
ruleSVBGaussianControlledVarianceZDNGD,
ruleSVBGaussianControlledVarianceΚDGND,
ruleSVBGaussianControlledVarianceΩDDN,
ruleMGaussianControlledVarianceGGDD,
ruleMGaussianControlledVarianceDGGD



function ruleSVBGaussianControlledVarianceOutNGDDD(dist_out::Nothing,
                                                   msg_x::Message{F, Univariate},
                                                   dist_z::ProbabilityDistribution{Univariate},
                                                   dist_κ::ProbabilityDistribution{Univariate},
                                                   dist_ω::ProbabilityDistribution{Univariate}) where F<:Gaussian

    dist_x = convert(ProbabilityDistribution{Univariate,GaussianMeanVariance},msg_x.dist)
    m_x = dist_x.params[:m]
    v_x = dist_x.params[:v]
    m_z, v_z = unsafeMeanCov(dist_z)
    m_κ, v_κ = unsafeMeanCov(dist_κ)
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    A = exp(-m_ω+v_ω/2)
    B = exp(-m_κ*m_z + ksi/2)


    return Message(Univariate, GaussianMeanVariance, m=m_x, v=v_x+inv(A*B))
end


function ruleSVBGaussianControlledVarianceOutNGDD(dist_out::Nothing,
                                                   msg_x::Message{F1, Univariate},
                                                   dist_z_κ::ProbabilityDistribution{Multivariate, F2},
                                                   dist_ω::ProbabilityDistribution{Univariate}) where {F1<:Gaussian, F2<:Gaussian}

    dist_x = convert(ProbabilityDistribution{Univariate,GaussianMeanVariance},msg_x.dist)
    dist_z_κ = convert(ProbabilityDistribution{Multivariate, GaussianMeanVariance},dist_z_κ)
    m_x = dist_x.params[:m]
    v_x = dist_x.params[:v]
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    A = exp(-m_ω+v_ω/2)
    B = quadratureExpectationExp(dist_z_κ,10)


    return Message(Univariate, GaussianMeanVariance, m=m_x, v=v_x+inv(A*B))
end

function ruleSVBGaussianControlledVarianceXGNDDD(msg_out::Message{F, Univariate},
                                                   dist_x::Nothing,
                                                   dist_z::ProbabilityDistribution{Univariate},
                                                   dist_κ::ProbabilityDistribution{Univariate},
                                                   dist_ω::ProbabilityDistribution{Univariate}) where F<:Gaussian

    dist_out = convert(ProbabilityDistribution{Univariate,GaussianMeanVariance},msg_out.dist)
    m_out = dist_out.params[:m]
    v_out = dist_out.params[:v]
    m_z, v_z = unsafeMeanCov(dist_z)
    m_κ, v_κ = unsafeMeanCov(dist_κ)
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    A = exp(-m_ω+v_ω/2)
    B = exp(-m_κ*m_z + ksi/2)

    return Message(Univariate, GaussianMeanVariance, m=m_out, v=v_out+inv(A*B))
end


function ruleSVBGaussianControlledVarianceXGNDD(msg_out::Message{F1, Univariate},
                                                   dist_x::Nothing,
                                                   dist_z_κ::ProbabilityDistribution{Multivariate, F2},
                                                   dist_ω::ProbabilityDistribution{Univariate}) where {F1<:Gaussian, F2<:Gaussian}

    dist_out = convert(ProbabilityDistribution{Univariate,GaussianMeanVariance},msg_out.dist)
    dist_z_κ = convert(ProbabilityDistribution{Multivariate, GaussianMeanVariance},dist_z_κ)
    m_out = dist_out.params[:m]
    v_out = dist_out.params[:v]
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    A = exp(-m_ω+v_ω/2)
    B = quadratureExpectationExp(dist_z_κ,10)

    return Message(Univariate, GaussianMeanVariance, m=m_out, v=v_out+inv(A*B))
end


function ruleSVBGaussianControlledVarianceZDNDD(dist_out_x::ProbabilityDistribution{Multivariate, F},
                                                dist_z::Nothing,
                                                dist_κ::ProbabilityDistribution{Univariate},
                                                dist_ω::ProbabilityDistribution{Univariate}) where F<:Gaussian

    dist_out_x = convert(ProbabilityDistribution{Multivariate,GaussianMeanVariance},dist_out_x)
    m = dist_out_x.params[:m]
    v = dist_out_x.params[:v]
    m_κ, v_κ = unsafeMeanCov(dist_κ)
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    Psi = (m[1]-m[2])^2+v[1,1]+v[2,2]-v[1,2]-v[2,1]
    A = exp(-m_ω+v_ω/2)

    return Message(Univariate, ExponentialLinearQuadratic, a=m_κ, b=Psi*A,c=-m_κ,d=v_κ)
end

function ruleSVBGaussianControlledVarianceΚDDND(dist_out_x::ProbabilityDistribution{Multivariate, F},
                                                   dist_z::ProbabilityDistribution{Univariate},
                                                   dist_κ::Nothing,
                                                   dist_ω::ProbabilityDistribution{Univariate}) where F<:Gaussian

    dist_out_x = convert(ProbabilityDistribution{Multivariate,GaussianMeanVariance},dist_out_x)
    m = dist_out_x.params[:m]
    v = dist_out_x.params[:v]
    m_z, v_z = unsafeMeanCov(dist_z)
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    Psi = (m[1]-m[2])^2+v[1,1]+v[2,2]-v[1,2]-v[2,1]
    A = exp(-m_ω+v_ω/2)

    return Message(Univariate, ExponentialLinearQuadratic, a=m_z, b=Psi*A,c=-m_z,d=v_z)
end

function ruleSVBGaussianControlledVarianceΩDDDN(dist_out_x::ProbabilityDistribution{Multivariate, F},
                                                   dist_z::ProbabilityDistribution{Univariate},
                                                   dist_κ::ProbabilityDistribution{Univariate},
                                                   dist_ω::Nothing) where F<:Gaussian

    dist_out_x = convert(ProbabilityDistribution{Multivariate,GaussianMeanVariance},dist_out_x)
    m = dist_out_x.params[:m]
    v = dist_out_x.params[:v]
    m_z, v_z = unsafeMeanCov(dist_z)
    m_κ, v_κ = unsafeMeanCov(dist_κ)

    Psi = (m[1]-m[2])^2+v[1,1]+v[2,2]-v[1,2]-v[2,1]
    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    B = exp(-m_κ*m_z + ksi/2)

    return Message(Univariate, ExponentialLinearQuadratic, a=1.0, b=Psi*B,c=-1.0,d=0.0)
end

function ruleMGaussianControlledVarianceGGDDD(msg_out::Message{F1, Univariate},
                                              msg_x::Message{F2, Univariate},
                                              dist_z::ProbabilityDistribution{Univariate},
                                              dist_κ::ProbabilityDistribution{Univariate},
                                              dist_ω::ProbabilityDistribution{Univariate}) where {F1 <: Gaussian, F2 <: Gaussian}
    dist_out = convert(ProbabilityDistribution{Univariate,GaussianMeanPrecision},msg_out.dist)
    dist_x = convert(ProbabilityDistribution{Univariate,GaussianMeanPrecision},msg_x.dist)
    m_x = dist_x.params[:m]
    w_x = dist_x.params[:w]
    m_out = dist_out.params[:m]
    w_out = dist_out.params[:w]
    m_z, v_z = unsafeMeanCov(dist_z)
    m_κ, v_κ = unsafeMeanCov(dist_κ)
    m_ω, v_ω = unsafeMeanCov(dist_ω)

    ksi = m_κ^2*v_z + m_z^2*v_κ+v_z*v_κ
    A = exp(-m_ω+v_ω/2)
    B = exp(-m_κ*m_z + ksi/2)
    W = [w_out+A*B -A*B; -A*B w_x+A*B]
    m = inv(W)*[m_out*w_out; m_x*w_x]

    return ProbabilityDistribution(Multivariate, GaussianMeanPrecision, m=m, w=W)

end
