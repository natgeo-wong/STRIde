# STRIde: Shallow-to-Deep Transition Recognition and Identification

## Project Overview
The **STRIde** project focuses on understanding the transition from shallow, boundary-layer-driven clouds to deep, precipitating convection. This transition is a critical component for improving global climate models. By utilizing NASA's NCEP/CPC Gridded Merged-IR Dataset and ARM Observations, we aim to improve the identification and tracking of the **Shallow-to-Deep Transition (STDT)** of Convection. The ultimate goal is to spearhead future research into the large-scale environmental factors that favor and facilitate these STDT events as part of the larger UNSHADE project. This particular project aims to:

* **Detect all convective events:** Identify both shallow and deep convection over the Southern Great Plains (SGP) ARM Facility.
* **Identification of STDT events:** Locate STDT events in ARM observations and validate them against the Merged-IR Dataset.
* **Classify Variability:** Understand and categorize the differences between various types of STDT events.

## Installation Instructions
This code base is using the [Julia Language](https://julialang.org/) and
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> STRIde

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
1. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate "STRIde"
```
which auto-activate the project and enable local path handling from DrWatson.

---

## Data Sources
* **NCEP/CPC Merged-IR:** Gridded Brightness Temperature ($T_{b}$) for feature detection.
* **sgpmicrobase (ARM):** Liquid and ice water content variables rebinned into minute-wise data with 100-meter height bounds.
* **ERA5:** Vertical profiles used for compositing environmental states.

---

## Target Site
The primary focus is the **Southern Great Plains (SGP) ARM facility**. While the Bankhead National Forest (BNF) site was considered, it currently lacks the necessary ice water content datasets required for this analysis.

---

## Acknowledgements
We acknowledge funding from the Department of Energy as part of the UNSHADE project.