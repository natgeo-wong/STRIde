using DrWatson
@quickactivate "STRIde"

using Dates, Statistics
using ARMLive
using Trapz

include(srcdir("common.jl"))

ads = ARMDataset(
    stream = "sgpmicrobasekaplusC1.c1",
    start = Date(2011), stop = Date(2021,12,31), path = datadir()
)

nz = 596;   tz = zeros(Float32,nz)
nt = 21600; dt = Int(1800 / (86400 / nt))

vname = "liquid_water_content"

dtvec = ads.start : Day(1) : ads.stop; ndt = length(dtvec)
attribs = Vector{Dict}(undef,3)

wcdata = zeros(48,nz,ndt)

for idt in 1 : ndt

    idata = @views wcdata[:,:,idt]
    ids = read(ads,vname,dtvec[idt],throw=false)
    if !isnothing(ids)
        attribs[1] = Dict(ids.attrib)
        attribs[2] = Dict(ids["height"].attrib)
        attribs[3] = Dict(ids[vname].attrib)

        NCDatasets.load!(ids["height"].var,tz,:)
        idata .= nomissing(ids[vname][:,1:dt:end],NaN)

        close(ids)

    end

end

fnc = joinpath(ads.path,"$(ads.stream)-$vname-$(ymd2str(ads.start))-$(ymd2str(ads.stop))-hourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c",attrib=attribs[1])

defDim(ds,"time",  48*ndt)
defDim(ds,"height",  nz)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since $(ads.start) 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))
ncz  = defVar(ds,"height",Float32,("height",),attrib=attribs[2])
ncwc = defVar(ds,vname,Float64,("height","time",),attrib=attribs[3])

nct[:] = collect(0 : 30 : (1440*ndt))[1:(end-1)]
ncz[:] = tz[:]
ncwc[:] = reshape(wcdata,nz,:)

close(ds)