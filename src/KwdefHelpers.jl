module KwdefHelpers

using Accessors

export kwdef_defaults

struct Throws{E}
    e::E
end

_eval(code, kwargs, x::Core.SSAValue) = _eval(code, kwargs, code[x.id])
_eval(code, kwargs, x::GlobalRef) = eval(x)
_eval(code, kwargs, x) = x

function _eval(code, kwargs, x::Core.SlotNumber)
    assignment = filter(c -> Base.isexpr(c, :(=)) && c.args[1] == x, code) |> only
    _eval(code, kwargs, assignment.args[2])
end

function _eval(code, kwargs, x::Expr)
    x = @modify(x.args[∗] |> If(a -> !(a isa GlobalRef))) do v
        _eval(code, kwargs, v)
    end
    uke = filter(a -> a isa UndefKeywordError, x.args)
    length(uke) == 1 && return get(kwargs, only(uke).var, Throws(only(uke)))
    thrs = filter(a -> a isa Throws, x.args)
    isempty(thrs) || return first(thrs)
    eval(x)
end

"""
    kwdef_defaults(::Type{T}; kwargs...)::NamedTuple

Evaluate the default argument values for a type `T` that was defined with `@kwdef`.
Returns an empty `NamedTuple` for non-`@kwdef` structs.

Pass `kwargs...` to override the defaults or provide additional arguments.

Note: `kwdef_defaults()` uses code introspection to extract the default values, it is not recommended for use in performance-critical code.

# Examples

```julia
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
"""
kwdef_defaults(::Type{T}; kwargs...) where {T} = kwargs_defaults(T; kwargs...)

function kwargs_defaults(f; kwargs...)
    m = try
        which(f, Tuple{})
    catch e
        occursin(r"no .*method", string(e)) && return (;)
        rethrow()
    end
    kwnames = Base.kwarg_decl(m) |> Tuple
    isempty(kwnames) && return (;)

    ci = code_lowered(f)[1]
    @assert ci.code[end] isa Core.ReturnNode
    constructor = ci.code[end-1]
    @assert Base.isexpr(constructor, :call)
    kwargslots = constructor.args[2:end-1]

    vals = map(sl -> _eval(ci.code, kwargs, sl), kwargslots) |> Tuple
    kws = NamedTuple{kwnames}(vals)
    _filter(v -> !(v isa Throws{UndefKeywordError}), kws)
end

# XXX: remove when released in Julia
_filter(f, xs::NamedTuple) = xs[filter(k -> f(xs[k]), keys(xs))]

end
