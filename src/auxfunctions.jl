__precompile__()
using LinearAlgebra
using Printf
using Random
using ProximalOperators
using PolynomialRoots

####################################

"""
FindCircumcentermSet(X)

Finds the Circumcenter of linearly independent vectors ``x_0,x_1,…,x_m``, columns of matrix ``X``,
as described in [^Behling2018a] and [^Behling2018b].

[^Behling2018a]: Behling, R., Bello Cruz, J.Y., Santos, L.-R.:
Circumcentering the Douglas–Rachford method. Numer. Algorithms. 78(3), 759–776 (2018).
[doi:10.1007/s11075-017-0399-5](https://doi.org/10.1007/s11075-017-0399-5)
[^Behling2018b]: Behling, R., Bello Cruz, J.Y., Santos, L.-R.:
On the linear convergence of the circumcentered-reflection method. Oper. Res. Lett. 46(2), 159-162 (2018).
[doi:10.1016/j.orl.2017.11.018](https://doi.org/10.1016/j.orl.2017.11.018)
"""
function FindCircumcentermSet(X)
    # Finds the Circumcenter of  linearly independent points  X = [X1, X2, X3, ... Xn]
        # println(typeof(X))
        lengthX = length(X)
        if lengthX  == 1
            return X[1]
        elseif lengthX == 2
            return .5*(X[1] + X[2])
        end
        V = []
        b = Float64[]
        # Forms V = [X[2] - X[1] ... X[n]-X[1]]
        # and b = [dot(V[1],V[1]) ... dot(V[n-1],V[n-1])]
        for ind in 2:lengthX
            difXnX1 = X[ind]-X[1]
            push!(V,difXnX1)
            push!(b,dot(difXnX1,difXnX1))
        end

       # Forms Gram Matrix
        dimG = lengthX-1
        G = diagm(b)

        for irow in 1:(dimG-1)
            for icol in  (irow+1):dimG
                G[irow,icol] = dot(V[irow],V[icol])
                G[icol,irow] = G[irow,icol]
            end
        end
        # println(rank(G))
        y = G\b
        # if isposdef(G)
        #     L = cholesky(G)
        #     y = L\b
        # else
        #     @warn "Gram matrix is not SPD"
        #     L = qr(G)
        #     y=L\b
        # end
        CC = X[1]
        for ind in 1:dimG
            CC += .5*y[ind]*V[ind]
        end
        return CC
    end
####################################
"""
    proj = ProjectIndicator(indicator,x)
    Projection using Indicator Function from `ProximalOperators.jl`
    """
    function ProjectIndicator(indicator,x)
        proj, fproj = prox(indicator,x)
        return proj
    end

####################################
    """
    reflec = ReflectIndicator(indicator,x)
    Reflection using Indicator Function from `ProximalOperators.jl`
    """
    function ReflectIndicator(indicator,x)
        proj = ProjectIndicator(indicator,x)
        reflec = 2*proj - x
    end
####################################
function StartingPoint(n::Int64)
    ## Creates a random point in R^n
    x=zeros(n);
    while norm(x)<2
        x = randn(n);
    end
    # norm between 5 and 15
    foonorm = (15-5)*rand() + 5
    return foonorm*x/norm(x);
end

####################################
function StartingPoint(m::Int64,n::Int64)
    ## Creates a random point in R^{m\times n}
    X=zeros(m,n)
    for j in 1:n
        X[:,j] = StartingPoint(m)
    end
    return X
end
####################################
function printoOnFile(filename::String,printline::AbstractArray; deletefile::Bool=false)
    if isempty(filename)
        return
    end
    if deletefile
        try
            rm(filename)
        catch e
            @warn e
        end
    end
    open(filename,"a") do file
        writedlm(file,printline)
    end
end
####################################


"""
        ProjectEpiQuadratic(s,v,α)
Project ``(s,v) ∈ R^{n+1}`` onto the epigraph of ``f(x) = αx^Tx``, such that ``f(v) '≤ s``.
"""
function ProjectEpiQuadratic(s::Number,v::Union{AbstractArray,Number}; α::Float64=1.0)
        if α*dot(v,v) <= s
                return s, v
        end
        #PolynomialCoefficients
        # a3μ³ + a2μ² + a1μ  + a0 = 0    
        a0 = s-α*dot(v,v)
        a1 = 4*α*s + 1.
        a2 = 4*α^2*s + 4*α
        a3 = 4*α^2
        r = roots([a0,a1,a2,a3])
        indexreal =  findall(x->abs.(x)<1e-12,imag.(r))
        μ  = (maximum(real.(r[indexreal])))
        x = 1/(1+2*α*μ ) * v
        t =  μ + s
        return t, x
end
####################################
"""
        ProjectEpiQuadratic(x,α)
Project ``x = [x₀,x̂] ∈ R^{n+1}`` onto the epigraph of ``f(u) = αu^Tu``, such that ``f(x̂) '≤ x₀   ``.
"""
function ProjectEpiQuadratic(x::AbstractArray; α::Float64=1.0)
    t, x = ProjectEpiQuadratic(x[1],x[2:end], α=α)
    return [t;x]
end

####################################
"""
    ApproxProject(x,g,∂g)

"""
function ApproxProject(x::Vector,g,∂g)
    gx = g(x)
    if gx ≤ 0
        return x
    else
        ∂gx = ∂g(x)
        return x .- (gx/dot(∂gx,∂gx))*∂gx
    end
end

####################################
"""
Reflection(x,fproj)
Reflection using any projection function `fproj`
"""
function Reflection(x,fproj)
    return 2*fproj(x) - x
end