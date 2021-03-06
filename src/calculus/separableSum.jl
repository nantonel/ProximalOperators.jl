# Separable sum, using tuples of arrays as variables

export SeparableSum

"""
**Separable sum of functions**

    SeparableSum(f₁,…,fₖ)

Given functions `f₁` to `fₖ`, returns their separable sum, that is
```math
g(x_1,…,x_k) = ∑_{i=1}^k f_i(x_i).
```
The object `g` constructed in this way can be evaluated at `Tuple`s of length `k`. Likewise, the `prox` and `prox!` methods for `g` operate with (input and output) `Tuple`s of length `k`.

Example:

    f = SeparableSum(NormL1(), NuclearNorm()); # separable sum of two functions
    x = randn(10); # some random vector
    Y = randn(20, 30); # some random matrix
    f_xY = f((x, Y)); # evaluates f at (x, Y)
    (u, V), f_uV = prox(f, (x, Y), 1.3); # computes prox at (x, Y)
"""
struct SeparableSum{T <: Tuple} <: ProximableFunction
    fs::T
end

SeparableSum(fs::Vararg{ProximableFunction}) = SeparableSum((fs...,))

is_prox_accurate(f::SeparableSum) = all(is_prox_accurate.(f.fs))
is_convex(f::SeparableSum) = all(is_convex.(f.fs))
is_set(f::SeparableSum) = all(is_set.(f.fs))
is_singleton(f::SeparableSum) = all(is_singleton.(f.fs))
is_cone(f::SeparableSum) = all(is_cone.(f.fs))
is_affine(f::SeparableSum) = all(is_affine.(f.fs))
is_smooth(f::SeparableSum) = all(is_smooth.(f.fs))
is_quadratic(f::SeparableSum) = all(is_quadratic.(f.fs))
is_generalized_quadratic(f::SeparableSum) = all(is_generalized_quadratic.(f.fs))
is_strongly_convex(f::SeparableSum) = all(is_strongly_convex.(f.fs))

function (f::SeparableSum)(x::TupleOfArrays{R}) where R <: Real
    sum = R(0)
    for k in eachindex(x)
        sum += f.fs[k](x[k])
    end
    return sum
end

function prox!(ys::TupleOfArrays{R}, fs::Tuple, xs::TupleOfArrays{R}, gamma::R=R(1)) where R <: Real
    sum = R(0)
    for k in eachindex(xs)
        sum += prox!(ys[k], fs[k], xs[k], gamma)
    end
    return sum
end

function prox!(ys::TupleOfArrays{R}, fs::Tuple, xs::TupleOfArrays{R}, gamma::Tuple) where R <: Real
    sum = R(0)
    for k in eachindex(xs)
        sum += prox!(ys[k], fs[k], xs[k], gamma[k])
    end
    return sum
end

prox!(ys::TupleOfArrays{R}, f::SeparableSum, xs::TupleOfArrays{R}, gamma=R(1)) where R <: Real = prox!(ys, f.fs, xs, gamma)

function gradient!(grad::TupleOfArrays{R}, fs::Tuple, x::TupleOfArrays{R}) where R <: Real
    val = R(0)
    for k in eachindex(fs)
        val += gradient!(grad[k], fs[k], x[k])
    end
    return val
end

gradient!(grad::TupleOfArrays, f::SeparableSum, x::TupleOfArrays) = gradient!(grad, f.fs, x)

fun_name(f::SeparableSum) = "separable sum"
fun_dom(f::SeparableSum) = "n/a"
fun_expr(f::SeparableSum) = "(x₁, …, xₖ) ↦ f₁(x₁) + … + fₖ(xₖ)"
fun_params(f::SeparableSum) = "n/a"

function prox_naive(f::SeparableSum, xs::TupleOfArrays{R}, gamma::Union{R, Tuple}=R(1)) where R <: Real
    fys = R(0)
    ys = []
    for k in eachindex(xs)
        y, fy = prox_naive(f.fs[k], xs[k], typeof(gamma) <: Real ? gamma : gamma[k])
        fys += fy
        append!(ys, [y])
    end
    return Tuple(ys), fys
end
