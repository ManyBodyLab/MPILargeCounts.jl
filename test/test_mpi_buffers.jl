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
    # small send/recv (single-buffer path)
    @testset "small send/recv" begin
        A = rand(5, 5)
        tag = 1001
        if rank != 0
            buf = split_buffer(MPI.serialize(A))
            MPILargeCounts._send_buffers(buf, 0, tag, comm)
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
        # create a byte vector and break into parts manually
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
    end

    # non-blocking send/receive using large_isend/large_ireceive
    @testset "nonblocking send/receive" begin
        B = [1, 3, 2, 3, 1.0, 321.321, 3.12313]
        tag = 3001
        if rank != 0
            reqs = MPILargeCounts.isend(B, comm; dest = 0, tag = tag)
            # do other work then wait
            MPI.Waitall(reqs)
        else
            for src in 1:(nprocs - 1)
                bytes, req = MPILargeCounts.irecv(comm; source = src, tag = tag)
                # blocking convenience wait
                MPI.Waitall(req)
                Brecv = MPI.deserialize(bytes)
                @test B ≈ Brecv
            end
        end
        MPI.Barrier(comm)
    end

    # large_bcast (root broadcasts large object)
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

    # allreduce for integers
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
