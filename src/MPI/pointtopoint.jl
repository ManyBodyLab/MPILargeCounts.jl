"""
    Send(buf, comm::Comm; dest::Integer, tag::Integer=0)

Perform a blocking send from the buffer `buf` to MPI rank `dest` of communicator
`comm` using the message tag `tag`.

    Send(obj, comm::Comm; dest::Integer, tag::Integer=0)

Complete a blocking send of an `isbits` object `obj` to MPI rank `dest` of
communicator `comm` using with the message tag `tag`.

"""
Send(data, comm::Comm; dest::Integer, tag::Integer = Cint(0)) =
    Send(data, dest, tag, comm)


function Send(buf::AbstractVector{<:Buffer}, dest::Integer, tag::Integer, comm::Comm)
    return _send_buffers(buf, dest, tag, comm)
end

"""
    send(obj, comm::Comm; dest::Integer, tag::Integer=0)

Complete a blocking send using a serialized version of `obj` to MPI rank
`dest` of communicator `comm` using with the message tag `tag`.
"""
send(obj, comm::Comm; dest::Integer, tag::Integer = 0) =
    send(obj, dest, tag, comm)
function send(obj, dest::Integer, tag::Integer, comm::Comm)
    buf = split_buffer(MPI.serialize(obj))
    return Send(buf, dest, tag, comm)
end

"""
    Isend(data, comm::Comm; dest::Integer, tag::Integer=0)

Starts a nonblocking send of `data` to MPI rank `dest` of communicator `comm` using with
the message tag `tag`.
"""
Isend(data, comm::Comm; dest::Integer, tag::Integer = 0) =
    Isend(data, dest, tag, comm)

function Isend(buf::AbstractVector{<:Buffer}, dest::Integer, tag::Integer, comm::Comm)
    return _isend_buffers(buf, dest, tag, comm)
end

"""
    isend(obj, comm::Comm; dest::Integer, tag::Integer=0)

Starts a nonblocking send of using a serialized version of `obj` to MPI rank
`dest` of communicator `comm` using with the message tag `tag`.

Returns the communication `Request` for the nonblocking send.
"""
isend(data, comm::Comm; dest::Integer, tag::Integer = 0) =
    isend(data, dest, tag, comm)
function isend(obj, dest::Integer, tag::Integer, comm::Comm)
    buf = split_buffer(MPI.serialize(obj))
    return Isend(buf, dest, tag, comm)
end

"""
    data = Recv!(recvbuf, comm::Comm;
            source::Integer=MPI.ANY_SOURCE, tag::Integer=MPI.ANY_TAG)

Completes a blocking receive into the buffer `recvbuf` from MPI rank `source` of communicator
`comm` using with the message tag `tag`.
"""
Recv!(recvbuf, comm::Comm, status = nothing; source = MPI.ANY_SOURCE[], tag = MPI.ANY_TAG[]) =
    Recv!(recvbuf, source, tag, comm, status)

function Recv!(recvbuf::AbstractVector{UInt8}, source::Integer, tag::Integer, comm::Comm, status::Union{Ref{Status}, Nothing})
    return _recv_buffers!(recvbuf, source, tag, comm)
end


"""
    obj = recv(comm::Comm;
            source::Integer=MPI.ANY_SOURCE, tag::Integer=MPI.ANY_TAG)

Completes a blocking receive of a serialized object from MPI rank `source` of communicator
`comm` using with the message tag `tag`.
"""
recv(comm::Comm, status = nothing; source::Integer = MPI.ANY_SOURCE[], tag::Integer = MPI.ANY_TAG[]) =
    recv(source, tag, comm, status)
function recv(source::Integer, tag::Integer, comm::Comm, status::Union{Ref{Status}, Nothing})
    buf = _recv_buffers(source, tag, comm)
    return MPI.deserialize(buf)
end


"""
    req = Irecv!(recvbuf, comm::Comm;
            source::Integer=MPI.ANY_SOURCE, tag::Integer=MPI.ANY_TAG)

Starts a nonblocking receive into the buffer `recvbuf` from MPI rank `source` of communicator
`comm` using the message tag `tag`.
"""
Irecv!(recvbuf, comm::Comm; source::Integer = MPI.ANY_SOURCE[], tag::Integer = MPI.ANY_TAG[]) =
    Irecv!(recvbuf, source, tag, comm)
function Irecv!(buf::AbstractVector{UInt8}, source::Integer, tag::Integer, comm::Comm)
    return _irecv_buffers!(buf, source, tag, comm)
end

function irecv(comm::Comm; source::Integer = MPI.ANY_SOURCE[], tag::Integer = MPI.ANY_TAG[])
    return irecv(source, tag, comm)
end
function irecv(source::Integer, tag::Integer, comm::Comm)
    buf, req = _irecv_buffers(source, tag, comm)
    return buf, req # Issue: The output is still serialized
end
