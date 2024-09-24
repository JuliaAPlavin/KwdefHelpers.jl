using TestItems
using TestItemRunner
@run_package_tests


@testitem "usage" begin
    f() = 456
    @kwdef struct MyS{T}
        somefield = 123
        another::Union{Int,Nothing} = nothing
        somemore
        lastone::Vector{T} = [1+2im, somemore, f()+4im, somefield]
    end

    @test kwdef_argvals(MyS) == (somefield = 123, another = nothing)
    @test kwdef_argvals(MyS; somemore=567) == (somefield = 123, another = nothing, somemore = 567, lastone = Number[1 + 2im, 567, 456 + 4im, 123])
end


@testitem "_" begin
    import Aqua
    Aqua.test_all(KwdefHelpers; ambiguities=false)
    Aqua.test_ambiguities(KwdefHelpers)

    import CompatHelperLocal as CHL
    CHL.@check()
end
