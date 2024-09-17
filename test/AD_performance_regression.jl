import Optimization
using ReverseDiff, Enzyme, BenchmarkTools, Test

lookup_pg = Dict(5 => 11, 4 => 13, 2 => 15, 3 => 17, 1 => 19)
ref_gen_idxs = [5, 4, 2, 3, 1]
cost_arrs = Dict(5 => [0.0, 1000.0, 0.0],
    4 => [0.0, 4000.0, 0.0],
    2 => [0.0, 1500.0, 0.0],
    3 => [0.0, 3000.0, 0.0],
    1 => [0.0, 1400.0, 0.0])

opf_objective = let lookup_pg = lookup_pg, ref_gen_idxs = ref_gen_idxs,
    cost_arrs = cost_arrs

    function (x, _)
        #start = time()
        cost = 0.0
        for i in ref_gen_idxs
            pg = x[lookup_pg[i]]
            _cost_arr = cost_arrs[i]
            cost += _cost_arr[1] * pg^2 + _cost_arr[2] * pg + _cost_arr[3]
        end
        #total_callback_time += time() - start
        return cost
    end
end

optprob = Optimization.OptimizationFunction(opf_objective,
    Optimization.AutoReverseDiff(true))

test_u0 = [
    0.6292298794022337,
    0.30740951571225206,
    0.0215258802699263,
    0.38457509230779996,
    0.9419186480931858,
    0.34961116773074874,
    0.875763562401991,
    0.3203478635827923,
    0.6354060958226175,
    0.45537545721771266,
    0.3120599359696674,
    0.2421238802331842,
    0.886455177641366,
    0.49797378087768696,
    0.652913329799645,
    0.03590201299300255,
    0.5618806749518928,
    0.8142146688533769,
    0.3973557130434364,
    0.27827135011662674,
    0.16456134856048643,
    0.7465018431665373,
    0.4898329811551083,
    0.6966035226583556,
    0.7419662648518377,
    0.8505905798503723,
    0.27102126066405097,
    0.1988238097281576,
    0.09684601934490256,
    0.49238142828542797,
    0.1366594202307445,
    0.6337080281764231,
    0.28814906958008235,
    0.5404996094640431,
    0.015153517398975858,
    0.6338449294034381,
    0.5165464961007717,
    0.572879113636733,
    0.9652420600585092,
    0.26535868365228543,
    0.865686920119479,
    0.38426996353892773,
    0.007412077949221274,
    0.3889835001514599
]
test_obj = 7079.190664351089
test_cons = [
    0.0215258802699263,
    -1.0701734802505833,
    -5.108902216849063,
    -3.49724505910433,
    -2.617834191007569,
    0.5457423426033834,
    -0.7150251969424766,
    -2.473175092089014,
    -2.071687022809815,
    -1.5522321037165985,
    -1.0107399030803794,
    3.0047739260369246,
    0.2849522377447594,
    -2.8227966798520674,
    3.2236954017592256,
    1.0793383525116511,
    -1.633412293595111,
    -3.1618224299953224,
    -0.7775962590542184,
    1.7252573527333024,
    -4.23535583005632,
    -1.7030832394691608,
    1.5810450617647889,
    -0.33289810365419437,
    0.19476447251065077,
    1.0688558672739048,
    1.563372246165339,
    9.915310272572729,
    1.4932615291788414,
    2.0016715378998793,
    -1.4038702698147258,
    -0.8834081057449231,
    0.21730536348839036,
    -7.40879932706212,
    -1.6000837514115611,
    0.8542376821320647,
    0.06615508569119477,
    -0.6077039991323074,
    0.6138802155526912,
    0.0061762164203837955,
    -0.3065125522705683,
    0.5843454392910835,
    0.7251928172073308,
    1.2740182727083802,
    0.11298343104675009,
    0.2518186223833513,
    0.4202616621130535,
    0.3751697141306502,
    0.4019890236200105,
    0.5950107614751935,
    1.0021074654956683,
    0.897077248544158,
    0.15136310228960612
]
res = zero(test_u0)

_f = Optimization.instantiate_function(optprob,
    test_u0,
    Optimization.AutoReverseDiff(false),
    nothing; g = true)
_f.f(test_u0, nothing)
@test @ballocated($(_f.grad)($res, $test_u0)) > 0

_f2 = Optimization.instantiate_function(optprob,
    test_u0,
    Optimization.AutoReverseDiff(true),
    nothing; g = true)
_f2.f(test_u0, nothing)
@test @ballocated($(_f2.grad)($res, $test_u0)) > 0

_f3 = Optimization.instantiate_function(optprob,
    test_u0,
    Optimization.AutoEnzyme(),
    nothing; g = true)
_f3.f(test_u0, nothing)
@test @ballocated($(_f3.grad)($res, $test_u0)) == 0
