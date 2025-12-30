"""
    bcast(obj, comm::Comm; root::Integer=0)

Broadcast the object `obj` from rank `root` to all processes on `comm`. This is
able to handle arbitrary data.
"""
bcast(obj, comm::Comm; root::Integer = Cint(0)) =
    bcast(obj, root, comm)
function bcast(obj, root::Integer, comm::Comm)
    nprocs = MPI.Comm_size(comm)
    nprocs <= 1 && return obj

    if mpi_is_root(root, comm)
        buf = split_buffer(MPI.serialize(obj))
        N = length(buf) + 1
        reqs = Vector{MPI.Request}(undef, (nprocs - 1) * N)
        for dest in 0:(nprocs - 1)
            dest == root && continue
            pos = dest < root ? (dest * N + 1) : (dest - 1) * N + 1
            reqs[pos:pos+N-1] .= MPILargeCounts.Isend(buf, comm; dest = dest, tag = dest)
        end
        MPI.Waitall(reqs)
    else
        obj = MPILargeCounts.recv(comm; source = root, tag = mpi_rank(comm))
    end
    return obj
end

"""
    allreduce(obj, op, comm::Comm; root::Integer=0)
    allreduce!(obj, op, comm::Comm; root::Integer=0)

Performs elementwise reduction using the operator `op` on the object `obj` across all
ranks in `comm`, returning the reduced object on all ranks.
"""
function allreduce(data, op, comm::Comm; root::Integer = Cint(0))
    return allreduce(data, op, root, comm)
end

function allreduce(data, op, root::Integer, comm::Comm)
    obj = reduce(data, op, root, comm)
    return bcast(obj, comm; root = root)
end

function allreduce!(data, op, comm::Comm; root::Integer = Cint(0))
    return allreduce!(data, op, root, comm)
end

function allreduce!(data, op, root::Integer, comm::Comm)
    obj = reduce!(data, op, root, comm)
    return bcast(obj, comm; root = root)
end

"""
    reduce(obj, op, comm::Comm; root::Integer=0)
    reduce!(obj, op, comm::Comm; root::Integer=0)

Performs elementwise reduction using the operator `op` on the object `obj` on the 
root rank `root` of `comm`, returning the reduced object on rank `root`.
"""
function reduce(obj, op, comm::Comm; root::Integer = Cint(0))
    return reduce(obj, op, root, comm)
end
function reduce(obj, op, root::Integer, comm::Comm)
    obj = mpi_is_root(root, comm) ? copy(obj) : obj
    return reduce!(obj, op, root, comm)
end
function reduce!(obj, op, comm::Comm; root::Integer = Cint(0))
    return reduce!(obj, op, root, comm)
end
function reduce!(obj, op, root::Integer, comm::Comm)
    rank = mpi_rank(comm)
    isroot = rank == root
    comm_size = MPI.Comm_size(comm)
    comm_size <= 1 && return obj

    if isroot
        out = obj
        for r in 0:(comm_size - 1)
            r == root && continue
            obj_recv = MPILargeCounts.recv(comm; source = r, tag = r)
            out = op(out, obj_recv)
        end
    else
        MPILargeCounts.send(obj, comm; dest = root, tag = rank)
        out = nothing
    end
    return out
end

function reduce!(obj, ::typeof(+), root::Integer, comm::Comm)
    rank = mpi_rank(comm)
    isroot = rank == root
    comm_size = MPI.Comm_size(comm)
    comm_size <= 1 && return obj

    if isroot
        out = obj
        for r in 0:(comm_size - 1)
            r == root && continue
            obj_recv = MPILargeCounts.recv(comm; source = r, tag = r)
            out += obj_recv # optimized in-place addition
        end
    else
        MPILargeCounts.send(obj, comm; dest = root, tag = rank)
        out = nothing
    end

    return out
end
