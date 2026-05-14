using DrWatson
@quickactivate "STRIde"

using DelimitedFiles, Logging, Statistics
using GOES
using NASAMergedTb
using RegionGrids

g16 = GOESDataset(ID=16,product="ABI-L2-ACMC",path=datadir())
g19 = GOESDataset(ID=19,product="ABI-L2-ACMC",path=datadir())
geo = GeoRegion("SGP_LARGE",path=srcdir())
gvar = "BCM"

sname = "SGP"; sdata = readdlm(srcdir("armstations.txt"),',')
sID = sdata[:,1]
slon = sdata[findfirst(sID .== sname),2]
slat = sdata[findfirst(sID .== sname),3]

glon,glat = grid(g16);                ggrd = RegionGrid(geo,Point2.(glon,glat))
blon,blat = NASAMergedTb.btdlonlat(); bgrd = RegionGrid(geo,blon,blat)
imat = nearest(ggrd,bgrd)
ind  = findall(imat[:].==nearest(Point2(slon,slat),bgrd)); nind = length(ind)
iii = ind .== nearest(Point2(slon,slat),ggrd)

dtvec = Date(2017,4,19) : Day(1) : Date(2026,2,28); ndt = length(dtvec)
time = fill(DateTime(2000,1,1,0,0,0),288,ndt)
data = zeros(nind,288,ndt)

for (ii, dt) in enumerate(dtvec)

    ds = dt < Date(2024,10,15) ? read(g16,geo,gvar,dt,throw=false) : read(g19,geo,gvar,dt,throw=false)
    if !isnothing(ds)
        time[:,ii] .= ds["time"][:]
        tdata = reshape(nomissing(ds[gvar][:,:,:],NaN),:,288)
        data[:,:,ii] .= tdata[ind,:]
        close(ds)
    end

end

time = time[:]
data = reshape(data,nind,:)
ii = time .!== DateTime(2000,1,1,0,0,0)
time = time[ii]
data = data[:,ii]

ndata = zeros(2,48,ndt)

for (ii, dt) in enumerate(dtvec)

    iyr = year(dt)
    imo = month(dt)
    idy = day(dt)

    for it = 1 : 48

        idt = DateTime(iyr,imo,idy,0,0,0) + (it-1) * Minute(30)
        i1 = findlast(idt.>=time)
        i2 = findfirst(idt.<=time)
        idata1 = (!isnothing(i1)&&((idt-time[i1])<Minute(15))) ? data[:,i1] : fill(NaN,3)
        idata2 = (!isnothing(i2)&&((time[i2]-idt)<Minute(15))) ? data[:,i2] : fill(NaN,3)
        iidata1 = idata1[iii][1]
        iidata2 = idata2[iii][1]
        if iidata1 == iidata2
            ndata[1,it,ii] = iidata1
            ndata[2,it,ii] = mean(idata1.+idata2)/2
        elseif isnan(iidata1)
            ndata[1,it,ii] = iidata2
            ndata[2,it,ii] = mean(idata2)
        elseif isnan(iidata2)
            ndata[1,it,ii] = iidata1
            ndata[2,it,ii] = mean(idata1)
        else
            ndata[1,it,ii] = round(mean(idata1.+idata2)/2)
            ndata[2,it,ii] = mean(idata1.+idata2)/2
        end

    end

end

fnc = datadir("GOES-ACMC-20170419-20260228-hourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c")

defDim(ds,"time",ndt*48)

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since 2000-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))

nbcm = defVar(ds,"BCM",Float64,("time",),attrib=Dict(
    "long_name"     => "Binary Cloud Mask",
    "units"         => "0-1",
))

nacm = defVar(ds,"ACM",Float64,("time",),attrib=Dict(
    "long_name"     => "Averaged Cloud Mask",
    "units"         => "0-1",
))

nct.var[:] = (0 : (ndt*48-1))*30
nbcm[:] = ndata[1,:,:][:]
nacm[:] = ndata[2,:,:][:]

close(ds)