using Literate: Literate
using MPILarge

Literate.markdown(
    joinpath(pkgdir(MPILarge), "docs", "files", "README.jl"),
    joinpath(pkgdir(MPILarge));
    flavor = Literate.CommonMarkFlavor(),
    name = "README",
)
