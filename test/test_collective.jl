using MPILarge
using Test
using MPI
using MPILarge: mpi_size, mpi_rank, mpi_is_root

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nprocs = MPI.Comm_size(comm)


@testset "collective n=$(nprocs)" begin
    @testset "bcast" begin
        if rank == 0
            obj = [42, 43]
        else
            obj = nothing
        end
        res = MPILarge.bcast(obj, comm; root = 0)
        @test res == [42, 43]
        MPI.Barrier(comm)

        A = ones(UInt8, Int(typemax(Cint)) + 10)
        B = MPILarge.bcast(A, comm; root = 0)
        @test B == A
        A = B = nothing
        GC.gc()
    end

    @testset "reduce & allreduce" begin
        myval = rank + 1
        sumref = MPILarge.allreduce(myval, Base.:*, comm; root = 0)
        sumref_2 = MPILarge.reduce(myval, Base.:*, comm; root = 0)
        expected = prod(1:nprocs)
        @test sumref == expected
        if rank == 0
            @test sumref_2 == expected
        else
            @test isnothing(sumref_2)
        end
        sumref = MPILarge.allreduce(myval, Base.:+, comm; root = 0)
        sumref_2 = MPILarge.reduce!(myval, Base.:+, comm; root = 0)
        expected = sum(1:nprocs)
        @test sumref == expected
        if rank == 0
            @test sumref_2 == expected
        else
            @test isnothing(sumref_2)
        end

        MPI.Barrier(comm)
    end
    MPI.Barrier(comm)
    MPI.Finalize()
    @test MPI.Finalized()
end
