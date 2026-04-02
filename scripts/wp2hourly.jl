using DrWatson
@quickactivate "STRIde"

using Dates, Statistics
using ARMLive

vname = "liquid_water_path"

ds1 = NCDataset(datadir("ARM","sgpmicrobasepi2C1.c1","sgpmicrobasepi2C1.c1-$(vname)-1996-01-01-2010-12-31.nc"))
t1  = ds1["time"][:]
wp1 = ds1[vname][:]
close(ds1)c

ds2 = NCDataset(datadir("ARM","sgpmicrobasekaplusC1.c1","sgpmicrobasekaplusC1.c1-$(vname)-1996-01-01-2010-12-31.nc"))
t2  = ds2["time"][:]
wp2 = ds2[vname][:]
close(ds2)

dtvec = DateTime(1996,1,1) : Minute(30) : DateTime(2021,12,31,23,30); ndt = length(dtvec)
wpath = zeros(ndt)

for idt in 1 : ndt

    dt = dtvec[idt]
    if dt < Date(2011)

        ii = dt .== t1
        wpath[idt] = wp1[ii]

    else

        ii = dt .== t2
        wpath[idt] = wp2[ii]

    end

end

fnc = datadir("ARM-$(vname)-compiledhourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c",attrib=attribs[1])

defDim(ds,"time",ndt)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "hours since 1996-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncwc = defVar(ds,"$vname",Float64,("time",),attrib=attribs[2])

nct[:] = dtvec
ncwc[:] = wpath

close(ds)