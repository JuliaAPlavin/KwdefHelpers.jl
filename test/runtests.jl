using TestItems
using TestItemRunner
@run_package_tests


@testitem "usage" begin
    using KwdefHelpers: kwargs_defaults

    struct MyS_NoKw
        a
    end
    @test kwdef_defaults(MyS_NoKw) == (;)

    g() = 456
    @kwdef struct MyS{T}
        somefield = 123
        another::Union{Int,Nothing} = nothing
        somemore
        lastone::Vector{T} = [1+2im, somemore + 1, g()+4im, somefield]
    end

    @test kwdef_defaults(MyS) == (somefield = 123, another = nothing)
    @test kwdef_defaults(MyS; somemore=567) == (somefield = 123, another = nothing, somemore = 567, lastone = Complex{Int64}[1 + 2im, 568 + 0im, 456 + 4im, 123 + 0im])

    f(x) = x
    f(; abc=123, x, def=x + 1) = abc + def
    f(x, y) = x
    @test kwargs_defaults(f) == (abc = 123,)
    @test kwargs_defaults(f; x=5) == (abc = 123, x = 5, def = 6)
end


@testitem "_" begin
    import Aqua
    Aqua.test_all(KwdefHelpers; ambiguities=false)
    Aqua.test_ambiguities(KwdefHelpers)

    import CompatHelperLocal as CHL
    CHL.@check()
end
