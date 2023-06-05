module OptimizationGCMAES

using Reexport
@reexport using Optimization
using GCMAES, Optimization.SciMLBase

export GCMAESOpt

struct GCMAESOpt end

SciMLBase.requiresbounds(::GCMAESOpt) = true
SciMLBase.allowsbounds(::GCMAESOpt) = true
SciMLBase.allowscallback(::GCMAESOpt) = false
SciMLBase.supports_opt_cache_interface(opt::GCMAESOpt) = true

function __map_optimizer_args(cache::OptimizationCache, opt::GCMAESOpt;
                              callback = nothing,
                              maxiters::Union{Number, Nothing} = nothing,
                              maxtime::Union{Number, Nothing} = nothing,
                              abstol::Union{Number, Nothing} = nothing,
                              reltol::Union{Number, Nothing} = nothing)

    # add optimiser options from kwargs
    mapped_args = (;)

    if !(isnothing(maxiters))
        mapped_args = (; mapped_args..., maxiter = maxiters)
    end

    if !(isnothing(maxtime))
        @warn "common maxtime is currently not used by $(opt)"
    end

    if !isnothing(abstol)
        @warn "common abstol is currently not used by $(opt)"
    end

    if !isnothing(reltol)
        @warn "common reltol is currently not used by $(opt)"
    end

    return mapped_args
end

function SciMLBase.__init(prob::OptimizationProblem, opt::GCMAESOpt;
                          maxiters::Union{Number, Nothing} = nothing,
                          maxtime::Union{Number, Nothing} = nothing,
                          abstol::Union{Number, Nothing} = nothing,
                          reltol::Union{Number, Nothing} = nothing,
                          progress = false,
                          σ0 = 0.2,
                          kwargs...)

    return OptimizationCache(prob, opt; maxiters, maxtime, abstol, reltol, progress,
                                   sigma0 = σ0, kwargs...)
end

function SciMLBase.__solve(cache::GCMAESOptimizationCache)
    local x
    local G = similar(cache.u0)

    _loss = function (θ)
        x = cache.f(θ, cache.p)
        return x[1]
    end

    if !isnothing(cache.f.grad)
        g = function (θ)
            cache.f.grad(G, θ)
            return G
        end
    end

    maxiters = Optimization._check_and_convert_maxiters(cache.solver_args.maxiters)
    maxtime = Optimization._check_and_convert_maxtime(cache.solver_args.maxtime)

    opt_args = __map_optimizer_args(cache, cache.opt, maxiters = maxiters,
                                    maxtime = maxtime,
                                    abstol = cache.abstol,
                                    reltol = cache.reltol; cache.solver_args...)

    t0 = time()
    if cache.sense === Optimization.MaxSense
        opt_xmin, opt_fmin, opt_ret = GCMAES.maximize(isnothing(cache.f.grad) ? _loss :
                                                      (_loss, g), cache.u0,
                                                      cache.solver_args.sigma0, cache.lb,
                                                      cache.ub; opt_args...)
    else
        opt_xmin, opt_fmin, opt_ret = GCMAES.minimize(isnothing(cache.f.grad) ? _loss :
                                                      (_loss, g), cache.u0,
                                                      cache.sigma0, cache.lb,
                                                      cache.ub; opt_args...)
    end
    t1 = time()

    SciMLBase.build_solution(cache, cache.opt,
                             opt_xmin, opt_fmin; retcode = Symbol(Bool(opt_ret)),
                             solve_time = t1 - t0)
end

end
