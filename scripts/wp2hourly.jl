using DrWatson
@quickactivate "STRIde"

using Dates, Logging, Statistics
using ARMLive

vname = "ice_water_path"

ds1 = NCDataset(datadir("ARM","sgpmicrobasepi2C1.c1","sgpmicrobasepi2C1.c1-$(vname)-19960101-20101231.nc"))
t1  = ds1["time"][1:180:end]
wp1 = nomissing(ds1[vname][1:180:end],NaN)
close(ds1)

ds2 = NCDataset(datadir("ARM","sgpmicrobasekaplusC1.c1","sgpmicrobasekaplusC1.c1-$(vname)-20110101-20211231.nc"))
t2  = ds2["time"][1:450:end]
wp2 = nomissing(ds2[vname][1:450:end],NaN)
close(ds2)

dtvec = DateTime(1996,1,1) : Minute(30) : DateTime(2021,12,31,23,30); ndt = length(dtvec)
wpath = zeros(ndt)*NaN

for idt in 1 : ndt

    dt = dtvec[idt]
    if dt < Date(2011)
        wpath[idt] = wp1[findfirst(dt.==t1)][1]
        iszero(mod(idt,100)) ? (@info idt) : nothing
    else
        wpath[idt] = wp2[findfirst(dt.==t2)][1]

    end

end

fnc = datadir("sgpmicrobase-$(vname)-compiledhourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c")

defDim(ds,"time",ndt)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since 1996-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncwc = defVar(ds,"$vname",Float64,("time",))

nct[:] = dtvec
ncwc[:] = wpath

close(ds)