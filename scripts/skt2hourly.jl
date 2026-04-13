using DrWatson
@quickactivate "STRIde"

using Dates, Logging, Statistics
using ARMLive

include(srcdir("common.jl"))

ads = ARMDataset(stream="sgpirt10mC1.b1",start=Date(1996),stop=Date(2021,12,31))
dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
wpath = zeros(48,ndt) * NaN

for idt in 1 : ndt

    ds = read(ads, dtvec[idt],throw=false)
    if !isnothing(ds)
        if ds.dim["time"] == 1440
            wpath[:, idt] = ds["sfc_ir_temp"][1:30:end]
        else
            wpath[2:48, idt] = ds["sfc_ir_temp"][29:30:end]
        end
    end
    close(ds)

end

fnc = datadir("ARM-$(sfc_ir_temp)-$(ymd2str(ads.start))-$(ymd2str(ads.stop))-hourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c")

defDim(ds,"time",ndt)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since 1996-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncwc = defVar(ds,"sfc_ir_temp",Float64,("time",),attrib=Dict(
    "long_name"     => "Surface Infra-Red Temperature",
    "units"         => "K",
    "valid_min"     => 223.0,
    "valid_max"     => 323.0,
    "valid_delta"   => 50.0,
    "resolution"    => 0.1
))

nct.var[:] = 0 : 30 : (ndt*30-1)
ncwc[:] = wpath[:]

close(ds)