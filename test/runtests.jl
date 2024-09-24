using TestItems
using TestItemRunner
@run_package_tests


@testitem "_" begin
    import Aqua
    Aqua.test_all(KwdefHelpers; ambiguities=false)
    Aqua.test_ambiguities(KwdefHelpers)

    import CompatHelperLocal as CHL
    CHL.@check()
end
