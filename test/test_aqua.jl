using MPILarge
using Aqua: Aqua
using Test
using TestExtras
using MPI

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nprocs = MPI.Comm_size(comm)


@testset "Code quality (Aqua.jl)" begin
    if nprocs == 1
        Aqua.test_all(MPILarge)
    end
    MPI.Finalize()
end
