using DrWatson
@quickactivate "STRIde"

using DelimitedFiles, Logging, Statistics
using GOESatellites
using NASAMergedTb
using RegionGrids

g16_BCM = GOESDataset("ABI-L2-ACM",sector="C",satellite=16,path=datadir())
g19_BCM = GOESDataset("ABI-L2-ACM",sector="C",satellite=19,path=datadir())
g16_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=16,path=datadir())
g19_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=19,path=datadir())
g16_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=16,path=datadir())
g19_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=19,path=datadir())

geo = GeoRegion("SGP_LARGE",path=srcdir())

dtbeg = minimum(vcat(g16_BCM.start, g16_COD.start, g16_CPS.start))
dtend = maximum(vcat(g19_BCM.stop, g19_COD.stop, g19_CPS.stop))
dtvec = dtbeg : Day(1) : dtend
ndt = length(dtvec)

ttmp = zeros(ndt,288,3)
t = zeros(ndt,288)

for idt = 1 : ndt
    dt = dtvec[idt]
    ds_BCM = dt < g19_BCM.start ? 
         read(g16_BCM,geo,"BCM",dt,throw=false) : 
         read(g19_BCM,geo,"BCM",dt,throw=false)
    ttmp[idt,:,1] .= nomissing(ds_BCM["time"][:],NaN)
    if !isnothing(ds_BCM)
        close(ds_BCM)
    end
    ds_COD = dt < g19_COD.start ? 
         read(g16_COD,geo,"COD",dt,throw=false) : 
         read(g19_COD,geo,"COD",dt,throw=false)
    ttmp[idt,:,2] .= nomissing(ds_COD["time"][:],NaN)
    if !isnothing(ds_COD)
        close(ds_COD)
    end
    if dt < Date(2023,12,4)
        ds_CPS = read(g16_CPS,geo,"PSD",dt,throw=false)
    elseif dt < g19_CPS.start
        ds_CPS = read(g16_CPS,geo,"CPS",dt,throw=false)
    else
        ds_CPS = read(g19_CPS,geo,"CPS",dt,throw=false)
    end
    ttmp[idt,:,3] .= nomissing(ds_CPS["time"][:],NaN)
    if !isnothing(ds_CPS)
        close(ds_CPS)
    end
end

for idt = 1 : ndt
    it = sort(unique(ttmp[idt,:,:])); nt = length(it)
    t[idt,1:nt] .= it
end

t = t[.!isnan.(t)]

fnc = datadir("GOES-t-$(Dates.format(dtbeg,dateformat"yyyymmdd"))-$(Dates.format(dtend,dateformat"yyyymmdd")).nc")
if isfile(fnc); rm(fnc,force=true) end
ds = NCDataset(fnc,"c")

defDim(ds,"time",length(t))

nct  = defVar(ds,"time",Float64,("time",),attrib=Dict(
    "units"     => "seconds since 2000-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))

nct.var[:] .= t

close(ds)