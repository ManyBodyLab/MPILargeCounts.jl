using Test
using MPI
using MPILargeCounts
using MPILargeCounts: split_buffer, _send_buffers, _recv_buffers

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nprocs = MPI.Comm_size(comm)

using Random
Random.seed!(12345)
 
@testset "mpi buffers n=$(nprocs)" begin
    @testset "small send/recv" begin
        A = rand(5, 5)
        tag = 1001
        if rank != 0
            buf = split_buffer(MPI.serialize(A))
            MPILargeCounts._send_buffers(buf, 0, tag, comm)
            MPILargeCounts._send_buffers(buf, 0, tag, comm)
        else
            for src in 1:(nprocs - 1)
                recv = MPILargeCounts._recv_buffers(src, tag, comm)
                A_recv = MPI.deserialize(recv)

                MPILargeCounts._recv_buffers!(recv, src, tag, comm)
                A_recv2 = MPI.deserialize(recv)

                @test A ≈ A_recv
                @test A ≈ A_recv2
            end
        end
        MPI.Barrier(comm)

        if rank != 0
            buf = split_buffer(MPI.serialize(A))
            MPILargeCounts._send_buffers(buf, 0, tag, comm)
        else
            for src in 1:(nprocs - 1)
                recv = MPILargeCounts._recv_buffers(src, tag, comm)
                A_recv = MPI.deserialize(recv)
                @test A ≈ A_recv
            end
        end
    end

    # multi-part send/recv (explicit parts)
    @testset "multipart send/recv" begin
        # TODO: Too large for GitHub runners
        # data = rand(UInt8, 50000, 50000)
        data = rand(100,300)
        bufs = split_buffer(MPI.serialize(data))
        tag = 2001
        if rank != 0
            MPILargeCounts._send_buffers(bufs, 0, tag, comm)
        else
            for src in 1:(nprocs - 1)
                recv = MPILargeCounts._recv_buffers(src, tag, comm)
                out = MPI.deserialize(recv)
                @test data ≈ out
            end
        end
        MPI.Barrier(comm)
        # Split into parts manually:
        data = rand(100)
        bufs = MPI.serialize(data)
        buffers = [MPI.Buffer(bufs[1:50]), MPI.Buffer(bufs[51:end])]
        if rank != 0
            MPILargeCounts._send_buffers(buffers, 0, tag, comm)
        else
            for src in 1:(nprocs - 1)
                req = MPI.Irecv!(Ref(Int(0)), src, tag, comm)
                MPI.Wait(req)
                recv = MPILargeCounts._recv_buffers!(bufs, [1:50,51:length(bufs)], src, tag, comm)
                out = MPI.deserialize(recv)
                @test data ≈ out
            end
        end
    end

    @testset "nonblocking send/receive" begin
        B = [1, 3, 2, 3, 1.0, 321.321, 3.12313]
        tag = 3001
        if rank != 0
            reqs = MPILargeCounts.isend(B, comm; dest = 0, tag = tag)
            MPI.Waitall(reqs)

            data = split_buffer(MPI.serialize(B))
            reqs = MPILargeCounts.Isend(data, comm; dest = 0, tag = tag)
            MPI.Waitall(reqs)

            MPILargeCounts.Send(data, comm; dest = 0, tag = tag)
        else
            for src in 1:(nprocs - 1)
                bytes, req = MPILargeCounts.irecv(comm; source = src, tag = tag)
                MPI.Waitall(req)
                Brecv = MPI.deserialize(bytes)
                @test B ≈ Brecv

                req = MPILargeCounts.Irecv!(bytes, comm; source = src, tag = tag)
                MPI.Waitall(req)
                Brecv2 = MPI.deserialize(bytes)
                @test B ≈ Brecv2

                bytes = MPILargeCounts.Recv!(bytes, comm; source = src, tag = tag)
                Brecv3 = MPI.deserialize(bytes)
                @test B ≈ Brecv3
            end
        end
        MPI.Barrier(comm)
    end

    @testset "bcast" begin
        tag = 0
        if rank == 0
            obj = rand(1000)
        else
            obj = nothing
        end
        res = MPILargeCounts.bcast(obj, comm; root = 0)
        # All ranks should now have same data
        if rank == 0
            @test res == obj
        else
            @test length(res) == 1000
        end
        MPI.Barrier(comm)
    end

    @testset "allreduce" begin
        myval = rank + 1
        sumref = MPILargeCounts.allreduce(myval, (a, b) -> a + b, comm; root = 0)
        # broadcasted result should be sum(1:nprocs)
        expected = sum(1:nprocs)
        @test sumref == expected

        MPI.Barrier(comm)
    end
end

# synchronize end of this test file
MPI.Barrier(comm)
MPI.Finalize()
@test MPI.Finalized()
