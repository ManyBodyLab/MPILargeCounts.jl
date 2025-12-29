# # MPILarge.jl

# `MPILarge.jl` is a Julia package that provides support for arbitrarily large MPI operations instead of the native `typemax(Cint)` limit. This is achieved by chunking the messages into smaller pieces and performing the collective operations on these chunks sequentially.
# The corresponding functions have the same name as in `MPI.jl`, but are not exported to avoid name clashes. To use the functions instead of the `MPI.jl`ones, you have to prefix them with `MPILarge.`.
# ## Installation

# The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

# ```julia-repl
# pkg> add git@github.com:ManyBodyLab/MPILarge.jl.git
# ```

# ## Code Samples

# When running with e.g. `2` MPI ranks:
# ```julia
# julia> using MPI, MPILarge
# julia> MPI.Init()
# julia> A = collect(1:Int(typemax(Cint))+10);
# julia> B = MPI.bcast(A, comm; root=0); # errors
# julia> B = MPILarge.bcast(A, comm; root=0);
# julia> B == A
# true
# true
# ```

# ## License

# MPILarge.jl is licensed under the [MIT License](LICENSE)). By using or interacting with this software in any way, you agree to the license of this software.
