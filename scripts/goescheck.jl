using DrWatson
@quickactivate "STRIde"

using GOESatellites

product = ARGS[1]
yr  = parse(Int, ARGS[3])
mo  = parse(Int, ARGS[4])
dy  = parse(Int, ARGS[5])

g16 = GOESDataset(product,sector="C",satellite=16,path=datadir())
g19 = GOESDataset(product,sector="C",satellite=19,path=datadir())
geo = GeoRegion("SGP_LARGE",path=srcdir())
gvar = ARGS[2]

for (ii, dt) in enumerate(Date(2017,4,19) : Day(1) : Date(2026,2,28))

    ds = dt < Date(yr,mo,dy) ? 
         read(g16,geo,gvar,dt,throw=false) : 
         read(g19,geo,gvar,dt,throw=false)
    if !isnothing(ds)
        close(ds)
    end

end