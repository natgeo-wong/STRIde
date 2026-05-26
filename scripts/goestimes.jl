using DrWatson
@quickactivate "STRIde"

using GOESatellites

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

ttmp = zeros(288,3,ndt) * NaN
t = zeros(300,ndt)*NaN
v = zeros(Int16,300,ndt,3)

for idt = 1 : ndt
    dt = dtvec[idt]
    if dt >= g16_BCM.start
        ds_BCM = dt < g19_BCM.start ?
                 read(g16_BCM,geo,"BCM",dt,throw=false) :
                 read(g19_BCM,geo,"BCM",dt,throw=false)
    else
        ds_BCM = nothing
    end
    if !isnothing(ds_BCM)
        ttmp[:,1,idt] .= nomissing(ds_BCM["time"].var[:],NaN)
        close(ds_BCM)
    end
    if dt >= g16_COD.start
        ds_COD = dt < g19_COD.start ?
                 read(g16_COD,geo,"COD",dt,throw=false) :
                 read(g19_COD,geo,"COD",dt,throw=false)
    else
        ds_COD = nothing
    end
    if !isnothing(ds_COD)
        ttmp[:,2,idt] .= nomissing(ds_COD["time"].var[:],NaN)
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
        ttmp[:,3,idt] .= nomissing(ds_CPS["time"].var[:],NaN)
        close(ds_CPS)
    end
end

for idt = 1 : ndt
    ittmp = ttmp[:,:,idt]
    it = sort(unique(ittmp[.!isnan.(ittmp)])); nt = length(it)
    #if nt > 288; @info [dtvec[idt],nt] end
    t[1:nt,idt] .= it
    for ii = 1 : nt
        iit = it[ii]
        v[ii,idt,1] = sum(iit.==ittmp[:,1])
        v[ii,idt,2] = sum(iit.==ittmp[:,2])
        v[ii,idt,3] = sum(iit.==ittmp[:,3])
    end
end

ii = .!isnan.(t)
t = t[ii]
v = reshape(v,:,3); v = v[ii[:],:]

fnc = datadir("GOES-t-$(Dates.format(dtbeg,dateformat"yyyymmdd"))-$(Dates.format(dtend,dateformat"yyyymmdd")).nc")
if isfile(fnc); rm(fnc,force=true) end
ds = NCDataset(fnc,"c")

defDim(ds,"time",length(t))
defDim(ds,"dataset",3)

nct = defVar(ds,"time",Float64,("time",),attrib=Dict(
    "units"     => "minutes since 2000-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))

ncv = defVar(ds,"validity",Int16,("time","dataset"),attrib=Dict(
    "units"     => "0-1",
    "long_name" => "validity",
    "datasets"  => "1=ACM,2=COD,3=CPS"
))

nct.var[:] .= t
ncv.var[:,:] .= v

close(ds)