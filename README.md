<!-- <img src="./docs/src/assets/logo_readme.svg" width="150"> -->

# MPILargeCounts.jl

| **Documentation** | **Downloads** |
|:-----------------:|:-------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Downloads][downloads-img]][downloads-url]

| **Build Status** | **Coverage** | **Style Guide** | **Quality assurance** |
|:----------------:|:------------:|:---------------:|:---------------------:|
| [![CI][ci-img]][ci-url] | [![Codecov][codecov-img]][codecov-url] | [![code style: runic][codestyle-img]][codestyle-url] | [![Aqua QA][aqua-img]][aqua-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://manybodylab.github.io/MPILargeCounts.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://manybodylab.github.io/MPILargeCounts.jl/dev

[doi-img]: https://zenodo.org/badge/DOI/
[doi-url]: https://doi.org/

[downloads-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FMPILarge&query=total_requests&label=Downloads
[downloads-url]: http://juliapkgstats.com/pkg/MPILargeCounts

[ci-img]: https://github.com/ManyBodyLab/MPILargeCounts.jl/actions/workflows/Tests.yml/badge.svg
[ci-url]: https://github.com/ManyBodyLab/MPILargeCounts.jl/actions/workflows/Tests.yml

[pkgeval-img]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/MPILargeCounts.svg
[pkgeval-url]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/MPILargeCounts.html

[codecov-img]: https://codecov.io/gh/ManyBodyLab/MPILargeCounts.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/ManyBodyLab/MPILargeCounts.jl

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[codestyle-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
[codestyle-url]: https://github.com/fredrikekre/Runic.jl

`MPILargeCounts.jl` is a Julia package that provides support for arbitrarily large MPI operations instead of the native `typemax(Cint)` limit. This is achieved by chunking the messages into smaller pieces and performing the collective operations on these chunks sequentially.
The corresponding functions have the same name as in `MPI.jl`, but are not exported to avoid name clashes. To use the functions instead of the `MPI.jl`ones, you have to prefix them with `MPILargeCounts.`.

## Installation

The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

```julia-repl
pkg> add git@github.com:ManyBodyLab/MPILargeCounts.jl.git
```

## Code Samples

When running with e.g. `2` MPI ranks:
```julia
julia> using MPI, MPILargeCounts
julia> MPI.Init()
julia> A = collect(1:Int(typemax(Cint))+10);
julia> B = MPI.bcast(A, comm; root=0); # errors
julia> B = MPILargeCounts.bcast(A, comm; root=0);
julia> B == A
true
true
```

## License

MPILargeCounts.jl is licensed under the [MIT License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
