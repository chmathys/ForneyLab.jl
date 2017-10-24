export Gaussian

abstract Gaussian <: SoftFactor

Univariate(family::Type{Gaussian}; kwargs...) = Univariate{family}(Dict(kwargs))
Multivariate(family::Type{Gaussian}; kwargs...) = Multivariate{family, size(kwargs[1][2])[1]}(Dict(kwargs))

vague(::Type{Univariate{Gaussian}}) = Univariate(Gaussian, m=0.0, v=huge)
vague(::Type{Multivariate{Gaussian, dims}}) = Multivariate(Gaussian, m=zeros(dims), V=huge*diageye(dims))

unsafeMean(dist::ProbabilityDistribution{Gaussian}) = deepcopy(ensureParameter!(dist, Val{:m}).params[:m]) # unsafe mean

unsafeVar(dist::Univariate{Gaussian}) = ensureParameter!(dist, Val{:v}).params[:v] # unsafe variance
unsafeVar(dist::Multivariate{Gaussian}) = diag(ensureParameter!(dist, Val{:V}).params[:V])

unsafeCov(dist::Univariate{Gaussian}) = ensureParameter!(dist, Val{:v}).params[:v] # unsafe covariance
unsafeCov(dist::Multivariate{Gaussian}) = deepcopy(ensureParameter!(dist, Val{:V}).params[:V])

function isProper(dist::Univariate{Gaussian})
    if isWellDefined(dist)
        if isValid(dist, :w)
            param = dist.params[:w]
        elseif isValid(dist, :v)
            param = dist.params[:v]
        else
            return false
        end

        return (realmin(Float64) < param < realmax(Float64))
    end
    
    return false
end

function isProper(dist::Multivariate{Gaussian})
    if isWellDefined(dist)
        if isValid(dist, :W)
            param = dist.params[:W]
        elseif isValid(dist, :V)
            param = dist.params[:V]
        else
            return false
        end
        
        return isRoundedPosDef(param)
    end
    
    return false
end

function isWellDefined(dist::Univariate{Gaussian})
    # Check if dist is not underdetermined
    location_valid = isValid(dist, :m) || isValid(dist, :xi)
    scale_valid    = isValid(dist, :v) || isValid(dist, :w)

    return location_valid && scale_valid
end

function isWellDefined(dist::Multivariate{Gaussian})
    # Check if dist is not underdetermined
    location_valid = isValid(dist, :m) || isValid(dist, :xi)
    scale_valid    = isValid(dist, :V) || isValid(dist, :W)

    if !location_valid || !scale_valid
        return false
    end

    dimensions=0
    for field in [:m, :xi, :V, :W]
        if haskey(dist.params, field) && isValid(dist.params[field]))
            if dimensions>0
                if maximum(size(dist.params[field])) != dimensions
                    return false
                end
            else
                dimensions = size(dist.params[field], 1)
            end
        end
    end

    return true
end

function sample(dist::Univariate{Gaussian})
    isProper(dist) || error("Cannot sample from improper distribution")
    ensureParameters!(dist, (:m, :v))
    return sqrt(dist.params[:v])*randn() + dist.params[:m]
end

function sample{dims}(dist::Multivariate{Gaussian, dims})
    isProper(dist) || error("Cannot sample from improper distribution")
    ensureParameters!(dist, (:m, :V))
    return chol(dist.params[:V])' *randn(dims) + dist.params[:m]
end

function prod!( x::Univariate{Gaussian},
                y::Univariate{Gaussian},
                z::Univariate{Gaussian}=Univariate(Gaussian, xi=0.0, w=1.0))

    ensureParameters!(x, (:xi, :w))
    ensureParameters!(y, (:xi, :w))

    z.params[:m] = NaN
    z.params[:v] = NaN
    z.params[:xi] = x.params[:xi] + y.params[:xi]
    z.params[:w] = x.params[:w] + y.params[:w]

    return z
end

function prod!( x::Multivariate{Gaussian, dims},
                y::Multivariate{Gaussian, dims},
                z::Multivariate{Gaussian, dims}=Multivariate(Gaussian, xi=zeros(dims), w=diageye(dims)))

    ensureParameters!(x, (:xi, :W))
    ensureParameters!(y, (:xi, :W))

    invalidate!(z, :m)
    invalidate!(z, :V)
    z.params[:xi] = x.params[:xi] + y.params[:xi]
    z.params[:W] = x.params[:W] + y.params[:W]

    return z
end

function ensureParameters!(dist::ProbabilityDistribution, params::Tuple{Symbol, Vararg{Symbol}})
    for param in params
        ensureParameter!(dist, Val{param})
    end
    return dist
end

# In all ensureParameter! methods we check if the required parameter defined and, if not, calculate it.
function ensureParameter!(dist::Univariate{Gaussian}, param::Type{Val{:m}})
    if !isValid(dist, :m)
        dist.params[:m] = ensureParameter!(dist, Val{:v}).params[:v] * dist.params[:xi]
    end
    return dist
end

function ensureParameter!(dist::Multivariate{Gaussian}, param::Type{Val{:m}})
    if !isValid(dist, :m)
        dist.params[:m] = ensureParameter!(dist, Val{:V}).params[:V] * dist.params[:xi]
    end
    return dist
end

function ensureParameter!(dist::Univariate{Gaussian}, param::Type{Val{:v}})
    if !isValid(dist, :v)
        dist.params[:v] = 1/dist.params[:w]
    end
    return dist
end

function ensureParameter!(dist::Multivariate{Gaussian}, param::Type{Val{:V}})
    if !isValid(dist, :V)
        dist.params[:V] = cholinv(dist.params[:W])
    end
    return dist
end

function ensureParameter!(dist::Univariate{Gaussian}, param::Type{Val{:xi}})
    if !isValid(dist, :xi)
        dist.params[:xi] = ensureParameter!(dist, Val{:w}).params[:w] * dist.params[:m]
    end
    return dist
end

function ensureParameter!(dist::Multivariate{Gaussian}, param::Type{Val{:xi}})
    if !isValid(dist, :xi)
        dist.params[:xi] = ensureParameter!(dist, Val{:W}).params[:W] * dist.params[:m]
    end
    return dist
end

function ensureParameter!(dist::Univariate{Gaussian}, param::Type{Val{:w}})
    if !isValid(dist, :w)
        dist.params[:w] = 1/dist.params[:v]
    end
    return dist
end

function ensureParameter!(dist::Multivariate{Gaussian}, param::Type{Val{:W}})
    if !isValid(dist, :W)
        dist.params[:W] = cholinv(dist.params[:V])
    end
    return dist
end

function ==(t::Univariate{Gaussian}, u::Univariate{Gaussian})
    if is(t, u)
        return true
    end
    ensureParameters!(t, (:xi, :w))
    ensureParameters!(u, (:xi, :w))
    return isApproxEqual(t.params[:xi], u.params[:xi]) && isApproxEqual(t.params[:w], u.params[:w])
end

function ==(t::Multivariate{Gaussian}, u::Multivariate{Gaussian})
    if is(t, u)
        return true
    end
    ensureParameters!(t, (:xi, :W))
    ensureParameters!(u, (:xi, :W))
    return isApproxEqual(t.params[:xi], u.params[:xi]) && isApproxEqual(t.params[:W], u.params[:W])
end

# Entropy functional
function differentialEntropy(dist::Univariate{Gaussian})
    return  0.5*log(unsafeCov(dist)) +
            0.5*log(2*pi) +
            0.5
end

function differentialEntropy{dims}(dist::Multivariate{Gaussian, dims})
    return  0.5*log(det(unsafeCov(dist))) +
            (dims/2)*log(2*pi) +
            (dims/2)
end