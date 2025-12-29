using MPILarge
using Test
using MPI
using MPILarge: mpi_size, mpi_rank, mpi_is_root

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nprocs = MPI.Comm_size(comm)

@testset "pointtopoint n=$(nprocs)" begin
    if nprocs != 1
        @testset "send_receive" begin
            obj = rank == 1 ? ("hello", [1, 2, 3]) : nothing
            tag = 4001
            if rank == 1
                MPILarge.send(obj, comm; dest = 0, tag = tag)
            else
                recv = MPILarge.recv(comm; source = 1, tag = tag)
                @test recv == ("hello", [1, 2, 3])
            end
            MPI.Barrier(comm)
        end

        @testset "isend_receive" begin
            obj = rank == 1 ? Dict(:a => 1, :b => 2) : nothing
            tag = 5001
            if rank == 1
                reqs = MPILarge.isend(obj, comm; dest = 0, tag = tag)
                MPI.Waitall(reqs)
            else
                bytes, req = MPILarge.irecv(comm; source = 1, tag = tag)
                MPI.Waitall(req)
                recv = MPI.deserialize(bytes)
                @test recv[:a] == 1 && recv[:b] == 2
            end
            MPI.Barrier(comm)
        end
    end
    MPI.Barrier(comm)
    MPI.Finalize()
    @test MPI.Finalized()
end
