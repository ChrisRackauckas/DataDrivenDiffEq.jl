# Based on StackOverflow
function subscriptnumber(i::Int)
    if i < 0
        c = [Char(0x208B)]
    else
        c = []
    end
    for d in reverse(digits(abs(i)))
        push!(c, Char(0x2080+d))
    end
    return join(c)
end

function gather_plot_information(x::AbstractDataDrivenProblem{N, C, D}) where {N,C, D}
    
    X = getfield(x, :X)
    Y = getfield(x, :Y)
    DX = getfield(x, :DX)
    U = getfield(x, :U)
    
    t = x.t 
    
    ylab = is_direct(x) ? "Sample ID" : "t"

    returns = []

    for (xi, si) in zip([X, DX, Y, U], ["x", "\U02202\U0209C"*"x", "y", "u"])
        isempty(xi) && continue
        push!(returns, (t, xi, si))
    end

    return returns, ylab
end


function gather_plot_information(x::DataDrivenDataset{N, C, D}) where {N,C, D}
    
    data = map([:X, :Y, :DX, :U]) do s
        reduce(hcat, map(x.probs) do prob
            getproperty(prob, s)
        end)
    end
    
    t = reduce(vcat, map(x.probs) do prob
        getproperty(prob, :t)
    end)
    
    ylab = is_direct(x) ? "Sample ID" : "t"

    returns = []

    for (xi, si) in zip(data, ["x", "\U02202\U0209C"*"x", "y", "u"])
        isempty(xi) && continue
        push!(returns, (t, xi, si))
    end

    return returns, ylab
end

function gather_plot_information(x::AbstractDataDrivenSolution)
    p = get_problem(x)
    X, _, t, u = get_oop_args(p)
    Y = get_target(p)
    
    ylab = is_direct(p) ? "Sample ID" : "t"
    
    outsym = is_direct(p) ? "y" : (is_discrete(p) ? "x" : "\U02202\U0209C"*"x")
    est_sym = outsym * "\U00302"
    Ŷ = x.basis(X, parameters(x), t, u)
    return [(t, Y, outsym), (t, Ŷ, est_sym)], ylab
end

## Problem

@recipe function probplot(p::AbstractDataDrivenProblem)
    plotins, ylab = gather_plot_information(p)

    layout := (length(plotins), 1)
    isdirec = is_direct(p)

    for (i, pins) in enumerate(plotins)
        yi, xi, lab = pins
        suff = isdirec ? "" : "(t)"
        @series begin
            if i > 1
                title := ""
            end
            label --> reduce(hcat, map(j->lab*subscriptnumber(j)*suff, 1:size(xi,1)))
            
            ylabel --> lab
            
            if length(plotins) == i
                xlabel --> ylab
            end

            subplot := i
            yi, permutedims(xi)
        end
    end

end

# Step 2...

## Solution !
# TODO Dispatch for SINDy to show a separate plot of the active
# terms in the candidates -> Need LatexStrings for that (most likely)
# Get the symbols of the states for plotting
# Add extreme values for error ? 

@recipe function resplot(x::AbstractDataDrivenSolution; show_data::Bool = false)
    plotins, xlab = gather_plot_information(x)
    isdirec = is_direct(get_problem(x))
    layout := (2,1)

    suff = isdirec ? "" : "(t)"

    t, Y, lab = plotins[1]
    _ , Ŷ, lab_ = plotins[2]
    

    @series begin
        label --> reduce(hcat, map(j->lab_*subscriptnumber(j)*suff, 1:size(Y, 1)))
        ylabel --> lab_
        subplot := 1
        seriestype := :path
        t, permutedims(Ŷ)
    end

    if show_data 
        @series begin
            label --> nothing
            ylabel --> lab
            subplot := 1
            seriestype --> :path
            primary := false
            linestyle --> :dash
            color --> :black
            t, permutedims(Y)
        end
    end


    elab = lab*suff*"-"*lab_*suff

    @series begin
        title := ""
        label --> reduce(hcat, map(j->"e"*subscriptnumber(j)*suff, 1:size(Y, 1)))
        ylabel --> elab
        subplot := 2
        xlabel --> xlab
        t, permutedims(Y-Ŷ)
    end

end