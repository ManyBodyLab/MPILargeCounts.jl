"""
Chunked communication based on MPI.jl with arbitrary-size data.
"""
module MPILargeCounts

# Convenience functions for MPI.jl
export mpi_execute_on_root, mpi_execute_on_root_and_bcast

using MPI
using MPI: Comm, Buffer, Datatype, Status

include("helper.jl")
include("mpi_chunking.jl")
include("MPI/collective.jl")
include("MPI/pointtopoint.jl")

end
