# KwdefHelpers.jl

Helper functions to work with `@kwdef`-defined structs.

Currently, only provides the `kwdef_defaults(T)` function that extracts default arguments:

```julia
    kwdef_defaults(::Type{T}; kwargs...)::NamedTuple

Evaluate the default argument values for a type `T` that was defined with `@kwdef`.
Returns an empty `NamedTuple` for non-`@kwdef` structs.

Pass `kwargs...` to override the defaults or provide additional arguments.

Note: `kwdef_defaults()` uses code introspection to extract the default values, it is not recommended for use in performance-critical code.

# Examples

julia> @kwdef struct MyS{T}
           somefield = 123
           another::Union{Int,Nothing} = nothing
           somemore
           lastone::Vector{T} = [1+2im, somemore, somefield]
       end

julia> kwdef_defaults(MyS)
(somefield = 123, another = nothing)

julia> kwdef_defaults(MyS; somemore=567)
(somefield = 123, another = nothing, somemore = 567, lastone = [1 + 2im, 567, 123])
```
