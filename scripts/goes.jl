using DrWatson
@quickactivate "STRIde"

using GOES

sID = parse(Int, ARGS[1])
yr  = parse(Int, ARGS[2])
mo  = parse(Int, ARGS[3])
gds = GOESDataset(ID=sID,product="ABI-L2-ACMC",path=datadir())
geo = GeoRegion("SGP_LARGE",path=srcdir())
gvar = "BCM"

download(gds,geo,gvar,start=Date(yr,mo),stop=Date(yr,mo,daysinmonth(yr,mo)),NT=UInt8)