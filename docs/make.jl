using MPILarge
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
    MPILarge, :DocTestSetup, :(using MPILarge); recursive = true
)

# Copy the license file into docs/src
cp(joinpath(@__DIR__, "..", "LICENSE"), joinpath(@__DIR__, "src", "LICENSE"); force = true)


include("make_index.jl")

makedocs(;
    modules = [MPILarge],
    authors = "Andreas Feuerpfeil <development@manybodylab.com>",
    sitename = "MPILarge.jl",
    format = Documenter.HTML(;
        canonical = "https://manybodylab.github.io/MPILarge.jl",
        edit_link = "main",
        assets = [#"assets/logo.png",
            "assets/extras.css",
        ],
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
    repo = "github.com/ManyBodyLab/MPILarge.jl", devbranch = "main", push_preview = true
)
