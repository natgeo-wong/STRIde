using DrWatson
@quickactivate "STRIde"

using Dates, Logging, Statistics
using ARMLive

include(srcdir("common.jl"))

ads = ARMDataset(stream="sgpirt10mC1.b1",start=Date(1996),stop=Date(2021,12,31),path=datadir())
dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
wpath = zeros(Float32,48,ndt) * NaN

for idt in 1 : ndt

    ds = read(ads, dtvec[idt],throw=false)
    if !isnothing(ds)
        if ds.dim["time"] == 1440
            wpath[:, idt] = nomissing(ds["sfc_ir_temp"][1:30:end],NaN)
        else
            it = ds["time"].var[:]
            iskt = ds["sfc_ir_temp"][:]
            for ii = 1 : 48
                iit = findfirst(it .== ((ii-1)*30))
                wpath[ii, idt] = !isnothing(iit) ? iskt[iit] : NaN
            end
        end
    close(ds)
    end

end

fnc = datadir("sgpirt10mC1-sfc_ir_temp-$(ymd2str(ads.start))-$(ymd2str(ads.stop))-hourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c")

defDim(ds,"time",ndt*48)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since 1996-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncwc = defVar(ds,"sfc_ir_temp",Float32,("time",),attrib=Dict(
    "long_name"     => "Surface Infra-Red Temperature",
    "units"         => "K",
    "valid_min"     => 223.0,
    "valid_max"     => 323.0,
    "valid_delta"   => 50.0,
    "resolution"    => 0.1
))

nct.var[:] = (0 : (ndt*48-1))*30
ncwc[:] = wpath[:]

close(ds)