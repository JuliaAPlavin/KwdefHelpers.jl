module KwdefHelpers

using AccessorsExtra

export kwdef_argvals

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

function kwdef_argvals(::Type{T}; kwargs...) where {T}
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
