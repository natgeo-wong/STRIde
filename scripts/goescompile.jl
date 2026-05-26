using DrWatson
@quickactivate "STRIde"

using DelimitedFiles, Logging, Statistics
using GOESatellites

g16_BCM = GOESDataset("ABI-L2-ACM",sector="C",satellite=16,path=datadir())
g19_BCM = GOESDataset("ABI-L2-ACM",sector="C",satellite=19,path=datadir())
g16_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=16,path=datadir())
g19_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=19,path=datadir())
g16_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=16,path=datadir())
g19_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=19,path=datadir())

geo = GeoRegion("SGP_LARGE",path=srcdir())

sname = "SGP"; sdata = readdlm(srcdir("armstations.txt"),',')
sID = sdata[:,1]
slon = sdata[findfirst(sID .== sname),2]
slat = sdata[findfirst(sID .== sname),3]
ggrd = RegionGrid(gds,geo)
ind  = nearest(Point2(slon,slat),ggrd)

dtbeg = maximum(vcat(g16_BCM.start, g16_COD.start, g16_CPS.start))
dtend = minimum(vcat(g19_BCM.stop, g19_COD.stop, g19_CPS.stop))
dtvec = dtbeg : Day(1) : dtend
ndt = length(dtvec)

ds = NCDataset(datadir("GOES-t-20170419-20260513.nc"))
t  = ds["time"][:]; ii = t[(t.>=dtbeg).&(t.<=dtend)]
t  = t[ii]
v  = dropdims(sum(ds["validity"][ii,2:3],dims=2),dims=2)
close(ds)

ii = .!iszero.(v)
t = t[ii]; nt = length(t)

data = zeros(nt,2)

for (idt, dt) = enumerate(dtvec)
    dt = dtvec[idt]
    if dt >= g16_COD.start
        ds_COD = dt < g19_COD.start ? 
                 read(g16_COD,geo,"COD",dt,throw=false) : 
                 read(g19_COD,geo,"COD",dt,throw=false)
    else
        ds_COD = nothing
    end
    if !isnothing(ds_COD)
        iit = ds_COD["time"][:]
        idata = reshape(nomissing(ds_COD["COD"][:,:,:],NaN),:,288)
        for ii in eachindex(iit)
            jj = findfirst(t.==iit[ii])
            data[jj,1] = idata[ind,ii]
        end
        close(ds_COD)
    end
    if dt >= g16_CPS.start
        if dt < Date(2023,12,4)
            ds_CPS = read(g16_CPS,geo,"PSD",dt,throw=false)
        elseif dt < g19_CPS.start
            ds_CPS = read(g16_CPS,geo,"CPS",dt,throw=false)
        else
            ds_CPS = read(g19_CPS,geo,"CPS",dt,throw=false)
        end
    else
        ds_CPS = nothing
    end
    if !isnothing(ds_CPS)
        iit = ds_CPS["time"][:]
        idata = dt < Date(2023,12,4) ? 
                reshape(nomissing(ds_CPS["PSD"][:,:,:],NaN),:,288) : 
                reshape(nomissing(ds_CPS["CPS"][:,:,:],NaN),:,288) 
        for ii in eachindex(iit)
            jj = findfirst(t.==iit[ii])
            data[jj,2] = idata[ind,ii]
        end
        close(ds_CPS)
    end
end

fnc = datadir("GOES-CODCPS-$(Dates.format(dtbeg,dateformat"yyyymmdd"))-$(Dates.format(dtend,dateformat"yyyymmdd")).nc")
if isfile(fnc); rm(fnc,force=true) end
ds = NCDataset(fnc,"c")

defDim(ds,"time",nt)

nct  = defVar(ds,"time",Float64,("time",),attrib=Dict(
    "units"     => "minutes since 2000-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))

ncCOD  = defVar(ds,"COD",Float64,("time",),attrib=Dict(
    "description"   => "ABI L2+ Cloud Optical Depth at 640 nm",
    "standard_name" => "atmosphere_optical_thickness_due_to_cloud",
    "units"         => "0-1"
))

ncCPS  = defVar(ds,"CPS",Float64,("time",),attrib=Dict(
    "description"   => "ABI L2+ Cloud Particle Size",
    "resolution"    => "y: 0.000056 rad x: 0.000056 rad",
    "standard_name" => "effective_radius_of_cloud_condensed_water_particles_at_cloud_top",
    "units"         => "um"
))

nct[:] .= t
ncCOD.var[:] .= data[:,1]
ncCPS.var[:] .= data[:,2]

close(ds)