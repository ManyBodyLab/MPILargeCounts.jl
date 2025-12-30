function mpi_barrier(blocking::Bool = true, comm::MPI.Comm = MPI.COMM_WORLD)
    (blocking && MPI.Initialized()) && (MPI.Barrier(comm))
    return nothing
end

mpi_size(com::MPI.Comm = MPI.COMM_WORLD) = MPI.Initialized() ? MPI.Comm_size(com) : Cint(1)
mpi_rank(comm::MPI.Comm = MPI.COMM_WORLD) = MPI.Initialized() ? MPI.Comm_rank(comm) : Cint(0)
mpi_is_root(root = Cint(0), comm::MPI.Comm = MPI.COMM_WORLD) = mpi_rank(comm) == root


""" 
    mpi_execute_on_root(F::A, args...; kwargs...)

Execute the function `F` with arguments `args...` and keyword arguments `kwargs...` on the root
of the communicator `comm` (default: `MPI.COMM_WORLD`). If `blocking` is set to `true` (default: `false`), a barrier is
performed before and after the execution to synchronize all ranks.
Returns the result of `F` on the root, and `nothing` on all other ranks.
"""
function mpi_execute_on_root(F::A, args...; blocking::Bool = false, comm::MPI.Comm = MPI.COMM_WORLD, root = Cint(0), kwargs...) where {A}
    mpi_barrier(blocking, comm)
    x = mpi_is_root(root, comm) ? F(args...; kwargs...) : nothing
    mpi_barrier(blocking, comm)
    return x
end

""" 
    mpi_execute_on_root_and_bcast(F::A, args...; kwargs...)
Execute the function `F` with arguments `args...` and keyword arguments `kwargs...` on the root
of the communicator `comm` (default: `MPI.COMM_WORLD`), and broadcast the result to all ranks.
Broadcasts the result of `F` on all ranks.
"""
function mpi_execute_on_root_and_bcast(F::A, args...; comm::MPI.Comm = MPI.COMM_WORLD, root = Cint(0), kwargs...) where {A}
    x = mpi_is_root(root, comm) ? F(args...; kwargs...) : nothing
    return MPILarge.bcast(x, comm; root = root)
end
