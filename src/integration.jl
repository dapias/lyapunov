include("./solver.jl")

using HDF5


println("Type the type of the potential (Harmonic oscillator (HO), Mexican Hat (MH), Quartic (Quartic)) ")
input = string(readline(STDIN))
potentialname = input[1:end-1]

potentiallist = ["HO", "MH", "Quartic"]

while !(potentialname in potentiallist)
  println("The potential you typed is not in our database. Try one of the following: \n HO, MH or Quartic or check the spelling")
  input = string(readline(STDIN))
  potentialname = input[1:end-1]
end

if potentialname == "HO"
    potential(x) = x^2/2.
elseif potentialname == "Quartic"
    potential(x) = x^4/4.
elseif potentialname == "MH"
    potential(x) = -1/2.*x^2 + 1/4.*x^4
end
    


T = 10.0
beta = 1./T;
Q = 2.0; #"mass" ot the thermostat;
r0 = initcond(beta, Q)
dt = 0.05
nsteps = 100000
tfinal= nsteps*dt

(t, xsol) = flowode45(DDfield, r0,dt, tfinal, potential, beta, Q)

x = map(v -> v[1], xsol)
y = map(v -> v[2], xsol)
z = map(v -> v[3], xsol);

tx = [t x y z]

filename = randstring(4)
file = h5open("$(filename)$(potentialname).hdf5", "w")

file["tx"] = tx
attrs(file)["Q"] = Q
attrs(file)["beta"] = beta
attrs(file)["potential"] = "$potentialname"
attrs(file)["dt"] = dt
attrs(file)["nsteps"] = nsteps

            
close(file)

println("File $(filename)$(potentialname).hdf5 succesfully generated")

#To call the file
# file = h5open("data.hdf5", "r")
# data = read(file, "tx")
