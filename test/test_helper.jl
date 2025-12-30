using MPILargeCounts
using Test
using MPI
using MPILargeCounts: mpi_size, mpi_rank, mpi_is_root

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nprocs = MPI.Comm_size(comm)

@testset "mpi helpers n=$(nprocs)" begin
    if nprocs != 1
        # basic init/size/rank/is_root helpers
        @testset "basic helpers" begin
            @test mpi_size() == nprocs
            @test mpi_rank() == rank
            @test isa(mpi_is_root(), Bool)
            if rank == 0
                @test mpi_is_root(0)
            else
                @test !mpi_is_root(0)
            end
            MPI.Barrier(comm)
        end

        # execute on root and return value only on root
        @testset "execute_on_root" begin
            f() = (rank == 0) ? (rand(3) .+ 1.0) : nothing
            res = mpi_execute_on_root(f; blocking = true)
            if rank == 0
                @test res !== nothing
            else
                @test res === nothing
            end
            MPI.Barrier(comm)
        end

        # execute on root and bcast result to all ranks
        @testset "execute_on_root_and_bcast" begin
            function make_obj()
                return rand(10)
            end
            res = mpi_execute_on_root_and_bcast(make_obj)
            @test length(res) == 10
            MPI.Barrier(comm)
        end
    end
    MPI.Barrier(comm)
    MPI.Finalize()
    @test MPI.Finalized()
end
