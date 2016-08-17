include("./RungeKutta.jl")
include("./randominitialcondition.jl")

using ForwardDiff
import ForwardDiff.derivative


function DDfield(r::Vector{Float64}, potential::Function, beta::Float64, Q::Float64)

    (q, p, z) = r

    force(x::Float64) = -derivative(potential,x)

    
    dq_dt = p
    dp_dt = force(q) + (1-exp(z - Q))/(1+exp(z-Q))*p/beta
    dz_dt = p^2. - 1.0/beta

    [dq_dt, dp_dt, dz_dt]

end

function forcederivative(potential::Function)
    force(x) = -derivative(potential,x)
    fprime(x) = derivative(force,x)

    return fprime

end

function jacobian(r_and_phi::Vector{Float64}, potential::Function, beta::Float64, Q::Float64)

    (q,p,z) = r_and_phi[1:3]
    
    fprime = forcederivative(potential)

    
    J = [0. 1. 0.; fprime(q)  (1-exp(z - Q))/(1+exp(z-Q))/beta p*(-2.0*exp(z-Q))/(1.0+exp(z-Q))^2./beta; 0. 2.0*p 0.]

end
    
    

function variationalDDfield(r_and_phi::Vector{Float64}, potential::Function, beta::Float64, Q::Float64)

    r = DDfield(r_and_phi[1:3], potential, beta, Q)

    J = jacobian(r_and_phi, potential, beta, Q)
   
    rmatrix = reshape(r_and_phi[4:end],3,3)
    DPhi = J*rmatrix'
    

    return append!(r, DPhi'[:])

end    

function flowRK(field::Function, r0::Vector{Float64},dt::Float64, tfinal::Float64, potential::Function, beta::Float64, Q::Float64)

    t = 0.0:dt:tfinal
    pos = copy(r0)

    function extendedfield(r::Vector{Float64})
        field(r, potential, beta, Q)
    end

    N = length(t) - 1
    for i in 1:N
        pos = rungeK(pos, extendedfield, dt)
    end

    return pos
end

function simulation(field::Function, r::Vector{Float64}, dt::Float64, dtsampling::Float64, nsteps::Int64, potential::Function, beta::Float64, Q::Float64)
    w = eye(3)
    norm1 = zeros(nsteps)
    norm2 = zeros(nsteps)
    norm3 = zeros(nsteps)
    phasespace = zeros(nsteps,3)

    for i in 1:nsteps
        phasespace[i,:] = r[1:3]
        r = flowRK(field, r, dt, dtsampling, potential, beta, Q) 
#        r[1:3] = pos[1:3]
        
        u = reshape(r[4:end],3,3)
        
        w = gramschmidt(u')
        norm1[i] = norm(w[:,1])
        norm2[i] = norm(w[:,2])
        norm3[i] = norm(w[:,3])

        w[:,1] = w[:,1]/norm(w[:,1])
        w[:,2] = w[:,2]/norm(w[:,2])
        w[:,3] = w[:,3]/norm(w[:,3])
        r[4:end] = copy(w'[:])

    end

    exp1 = sum(log(norm1))/(nsteps*dtsampling)
    exp2 = sum(log(norm2))/(nsteps*dtsampling)
    exp3 = sum(log(norm3))/(nsteps*dtsampling)

    println("Exponentes de Lyapunov: $exp1, $exp2, $exp3")

    return phasespace, norm1, norm2, norm3, exp1, exp2, exp3

end


function lyapunovspectra(field::Function, r::Vector{Float64}, dt::Float64, dtsampling::Float64, nsteps::Int64, potential::Function, beta::Float64, Q::Float64)
    w = eye(3)
    norm1 = zeros(nsteps)
    norm2 = zeros(nsteps)
    norm3 = zeros(nsteps)
#    phasespace = zeros(nsteps,3)

    for i in 1:nsteps
 #       phasespace[i,:] = r[1:3]
        r = flowRK(field, r, dt, dtsampling, potential, beta, Q) 
#        r[1:3] = pos[1:3]
        
        u = reshape(r[4:end],3,3)
        
        w = gramschmidt(u')
        norm1[i] = norm(w[:,1])
        norm2[i] = norm(w[:,2])
        norm3[i] = norm(w[:,3])

        w[:,1] = w[:,1]/norm(w[:,1])
        w[:,2] = w[:,2]/norm(w[:,2])
        w[:,3] = w[:,3]/norm(w[:,3])
        r[4:end] = copy(w'[:])

    end

    exp1 = sum(log(norm1))/(nsteps*dtsampling)
    exp2 = sum(log(norm2))/(nsteps*dtsampling)
    exp3 = sum(log(norm3))/(nsteps*dtsampling)

#    println("Exponentes de Lyapunov: $exp1, $exp2, $exp3")

    return norm1, norm2, norm3, exp1, exp2, exp3

end

function gramschmidt(u::Matrix{Float64})
     w = eye(3)
     w[:,1] = u[:,1];
     v1 = w[:,1]/norm(w[:,1])
     w[:,2] = u[:,2] - dot(u[:,2],v1)*v1;
     v2 = w[:,2]/norm(w[:,2]);
     w[:,3] = (u[:,3] - dot(u[:,3],v2)*v2 - dot(u[:,3],v1)*v1)
    
    return w
end


    
    
    

    