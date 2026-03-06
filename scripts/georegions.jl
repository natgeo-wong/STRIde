using DrWatson
@quickactivate "STRIde"

using DelimitedFiles
using GeoRegions

stnID = "SGP"
stninfo = readdlm(srcdir("armstations.txt"),',')
_,lon,lat = stninfo[stninfo[:,1] .== stnID, :]

geo_s = GeoRegion(
    [-1,1,1,-1,-1]*0.5.+lon,[-1,-1,1,1,-1]*0.5.+lat,
    ID = "$(stnID)_LOCAL", pID = "GLB", name = "Southern Great Plains (Local)"
); overwrite(geo_s,path=srcdir())

geo_b = GeoRegion(
    [-1,1,1,-1,-1]*10 .+lon,[-1,-1,1,1,-1]*10 .+lat,
    ID = "$(stnID)_LARGE", pID = "GLB", name = "Southern Great Plains (Regional)"
); overwrite(geo_b,path=srcdir())