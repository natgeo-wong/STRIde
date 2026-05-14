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

glon,glat = grid(g16); ggrd = RegionGrid(geo,Point2.(glon,glat))
ind  = nearest(Point2(slon,slat),ggrd,n=4); nind = length(ind)
ndata = zeros(2,48,ndt,nind)
data = zeros(7,288,ndt,nind)

dtvec = Date(2017,4,19) : Day(1) : Date(2026,2,28); ndt = length(dtvec)
time = fill(DateTime(2000,1,1,0,0,0),288,ndt)

ipnt = zeros(Int,7,nind)
for iind in 1 : nind
    ipnt[:,iind] = nearest(Point2.(ggrd.lon[iind],ggrd.lat[iind]),ggrd,n=7)
end

for (ii, dt) in enumerate(dtvec)

    ds = dt < Date(2024,10,15) ? read(g16,geo,gvar,dt,throw=false) : read(g19,geo,gvar,dt,throw=false)
    if !isnothing(ds)
        time[:,ii] .= ds["time"][:]
        tdata = reshape(nomissing(ds[gvar][:,:,:],NaN),:,288)
        for iind in 1 : nind
            data[:,:,ii,iind] .= tdata[ipnt[:,iind],:]
        end
        close(ds)
    end

end

time = time[:]
data = reshape(data,7,:,nind)
ii = time .!== DateTime(2000,1,1,0,0,0)
time = time[ii]
data = data[:,ii,:]

for (ii, dt) in enumerate(dtvec)

    iyr = year(dt)
    imo = month(dt)
    idy = day(dt)

    for it = 1 : 48

        idt = DateTime(iyr,imo,idy,0,0,0) + (it-1) * Minute(30)
        i1 = findlast(idt.>=time)
        i2 = findfirst(idt.<=time)

        for iind = 1 : nind
            idata1 = (!isnothing(i1)&&((idt-time[i1])<Minute(15))) ? data[:,i1,iind] : fill(NaN,3)
            idata2 = (!isnothing(i2)&&((time[i2]-idt)<Minute(15))) ? data[:,i2,iind] : fill(NaN,3)
            iidata1 = idata1[1]
            iidata2 = idata2[1]
            if iidata1 == iidata2
                ndata[1,it,ii,iind] = iidata1
                ndata[2,it,ii,iind] = mean(idata1.+idata2)/2
            elseif isnan(iidata1)
                ndata[1,it,ii,iind] = iidata2
                ndata[2,it,ii,iind] = mean(idata2)
            elseif isnan(iidata2)
                ndata[1,it,ii,iind] = iidata1
                ndata[2,it,ii,iind] = mean(idata1)
            else
                ndata[1,it,ii,iind] = round(mean(idata1.+idata2)/2)
                ndata[2,it,ii,iind] = mean(idata1.+idata2)/2
            end

        end

    end

end

fnc = datadir("GOES-ACMC-20170419-20260228-nearestneighbours-hourly.nc")
isfile(fnc) ? rm(fnc,force=true) : nothing
ds = NCDataset(fnc,"c")

defDim(ds,"time",ndt*48)
defDim(ds,"points",nind)

nclon  = defVar(ds,"longitude",Int32,("points",),attrib=Dict(
    "units"     => "degree_east",
    "long_name" => "longitude",
))

nclat  = defVar(ds,"latitude",Int32,("points",),attrib=Dict(
    "units"     => "degree_north",
    "long_name" => "latitude",
))

nct  = defVar(ds,"time",Int32,("time",),attrib=Dict(
    "units"     => "minutes since 2000-01-01 00:00:00.0",
    "long_name" => "time",
    "calendar"  => "gregorian",
))

nbcm = defVar(ds,"BCM",Float64,("time","points"),attrib=Dict(
    "long_name"     => "Binary Cloud Mask",
    "units"         => "0-1",
))
    
nacm = defVar(ds,"ACM",Float64,("time","points"),attrib=Dict(
    "long_name"     => "Averaged Cloud Mask",
    "units"         => "0-1",
))

nclon[:] = ggrd.lon[ind]
nclat[:] = ggrd.lat[ind]
nct.var[:] = (0 : (ndt*48-1))*30
nbcm[:] = reshape(ndata[1,:,:,:],:,nind)
nacm[:] = reshape(ndata[2,:,:,:],:,nind)

close(ds)