module KwdefHelpers

using AccessorsExtra

export kwdef_defaults

struct Throws{E}
    e::E
end

_eval(code, x::Core.SSAValue) = _eval(code, code[x.id])
_eval(code, x::GlobalRef) = eval(x)
_eval(code, x) = x

function _eval(code, x::Core.SlotNumber)
    assignment = filter(c -> Base.isexpr(c, :(=)) && c.args[1] == x, code) |> only
    _eval(code, assignment.args[2])
end

function _eval(code, x::Expr)
    x = @modify(x.args[∗] |> If(a -> !(a isa GlobalRef))) do v
        _eval(code, v)
    end
    uke = filter(a -> a isa UndefKeywordError, x.args)
    length(uke) == 1 ? Throws(only(uke)) : eval(x)
end

"""
    kwdef_defaults(::Type{T}; kwargs...) where {T}

Extract the default values arguments for a type `T` that was defined with `@kwdef`.

Pass `kwargs...` to override the defaults or provide additional arguments.

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
function kwdef_defaults(::Type{T}; kwargs...) where {T}
    m = first(methods(T))
    kwnames = Base.kwarg_decl(m) |> Tuple

    ci = code_lowered(T)[1]
    @assert ci.code[end] isa Core.ReturnNode
    constructor = ci.code[end-1]
    @assert Base.isexpr(constructor, :call)
    kwargslots = constructor.args[2:end-1]

    vals = map(sl -> _eval(ci.code, sl), kwargslots) |> Tuple
    vals = @modify(vals |> RecursiveOfType(Throws{UndefKeywordError})) do t
        get(kwargs, t.e.var, t)
    end
    kws = NamedTuple{kwnames}(vals)
    _filter(v -> isempty(getall(v, RecursiveOfType(Throws{UndefKeywordError}))), kws)
end

# XXX: remove when released in Julia
_filter(f, xs::NamedTuple) = xs[filter(k -> f(xs[k]), keys(xs))]

end
