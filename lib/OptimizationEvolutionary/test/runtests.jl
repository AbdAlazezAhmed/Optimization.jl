using OptimizationEvolutionary, Optimization
using Test

@testset "OptimizationEvolutionary.jl" begin
    rosenbrock(x, p) = (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
    x0 = zeros(2)
    _p = [1.0, 100.0]
    l1 = rosenbrock(x0, _p)
    optprob = OptimizationFunction(rosenbrock)
    prob = Optimization.OptimizationProblem(optprob, x0, _p)
    sol = solve(prob, CMAES(μ = 40, λ = 100), abstol = 1e-15)
    @test 10 * sol.objective < l1

    cons_circ = (res, x, p) -> res .= [x[1]^2 + x[2]^2]
    optprob = OptimizationFunction(rosenbrock; cons = cons_circ)
    prob = OptimizationProblem(optprob, x0, _p, lcons = [-Inf], ucons = [0.25^2])
    sol = solve(prob, CMAES(μ = 40, λ = 100))
    res = zeros(1)
    cons_circ(res, sol.u, nothing)
    @test res[1]≈0.0625 atol=1e-5
    @test sol.objective < l1
end
