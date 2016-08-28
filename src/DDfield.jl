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