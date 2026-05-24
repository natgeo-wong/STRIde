using DrWatson
@quickactivate "STRIde"

using GOESatellites

sID = parse(Int, ARGS[1])
yr  = parse(Int, ARGS[2])
mo  = parse(Int, ARGS[3])
try
    dy = parse(Int, ARGS[4])
catch
    dt = 1
end
gds = GOESDataset("ABI-L2-ACN",sector="C",satellite=sID,path=datadir())
geo = GeoRegion("SGP_LARGE",path=srcdir())
gvar = "BCM"

download(gds,geo,gvar,NT=UInt8,start=Date(yr,mo,dy),stop=Date(yr,mo,daysinmonth(yr,mo)))