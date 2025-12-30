const _mpi_message_size_limit = typemax(Cint)

function split_ranges(len::Integer)
    N = cld(len, _mpi_message_size_limit)
    # base size and remainder for even distribution
    base, rem = divrem(len, N)
    ranges = Vector{UnitRange{Int}}(undef, N)
    pos = 1
    for i in 1:N
        sz = base + (i <= rem ? 1 : 0)
        ranges[i] = pos:(pos + sz - 1)
        pos += sz
    end
    return ranges
end

"""
    split_buffer(vec)

Split an `AbstractVector` into a `Vector{MPI.Buffer}` views without copying.
"""
function split_buffer(vec::AbstractVector)::Vector{MPI.Buffer}
    r = split_ranges(length(vec))
    return [MPI.Buffer(view(vec, ri)) for ri in r]
end

# Workhorse send/receive functions
function _send_buffers(bufs::AbstractVector{<:MPI.Buffer}, dest::Integer, tag::Integer, comm::Comm)
    req = _isend_buffers(bufs, dest, tag, comm)
    MPI.Waitall(req)
    return nothing
end
function _isend_buffers(bufs::AbstractVector{<:MPI.Buffer}, dest::Integer, tag::Integer, comm::Comm)
    N = length(bufs)
    total = sum(Int, b.count for b in bufs)

    reqs = Vector{MPI.Request}(undef, N + 1)
    reqs[1] = MPI.Isend(Ref(total), dest, tag, comm)
    for (i, b) in enumerate(bufs)
        reqs[i + 1] = MPI.Isend(b, dest, tag + i, comm)
    end
    return reqs
end

function _recv_buffers(source::Integer, tag::Integer, comm::Comm)
    out, req = _irecv_buffers(source, tag, comm)
    MPI.Waitall(req)
    return out
end
function _recv_buffers!(buf::AbstractVector{UInt8}, source::Integer, tag::Integer, comm::Comm)
    req = _irecv_buffers!(buf, source, tag, comm)
    MPI.Waitall(req)
    return buf
end
function _recv_buffers!(buf::AbstractVector{UInt8}, ranges::Vector{UnitRange{Int}}, source::Integer, tag::Integer, comm::Comm)
    req = _irecv_buffers!(buf, ranges, source, tag, comm)
    MPI.Waitall(req)
    return buf
end

function _irecv_buffers(source::Integer, tag::Integer, comm::Comm)
    # total = MPI.recv(comm; source=source, tag=tag)
    total = Ref{Int}(0)
    req = MPI.Irecv!(total, comm; source = source, tag = tag)
    MPI.Wait(req)
    total = total[]

    ranges = split_ranges(total)
    out = Vector{UInt8}(undef, total)
    return out, _irecv_buffers!(out, ranges, source, tag, comm)
end
function _irecv_buffers!(buf::AbstractVector{UInt8}, source::Integer, tag::Integer, comm::Comm)
    total = Ref{Int}(0)
    req = MPI.Irecv!(total, comm; source = source, tag = tag)
    MPI.Wait(req)
    ranges = split_ranges(total[])
    return _irecv_buffers!(buf, ranges, source, tag, comm)
end
function _irecv_buffers!(buf::AbstractVector{UInt8}, ranges::Vector{UnitRange{Int}}, source::Integer, tag::Integer, comm::Comm)
    reqs = Vector{MPI.Request}(undef, length(ranges))
    for (i, r) in enumerate(ranges)
        reqs[i] = MPI.Irecv!(view(buf, r), comm; source = source, tag = tag + i)
    end
    return reqs
end
