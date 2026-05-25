using DrWatson
@quickactivate "STRIde"

using GOESatellites

geo = GeoRegion("SGP_LARGE",path=srcdir())

g16_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=16,path=datadir())
g19_COD = GOESDataset("ABI-L2-COD",sector="C",satellite=19,path=datadir())
for (ii, dt) in enumerate(Date(2017,6,8) : Day(1) : Date(2026,2,28))

    ds = dt < g19_COD.start ? 
         read(g16_COD,geo,"COD",dt,throw=false) : 
         read(g19_COD,geo,"COD",dt,throw=false)
    if !isnothing(ds)
        close(ds)
    end

end

g16_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=16,path=datadir())
g19_CPS = GOESDataset("ABI-L2-CPS",sector="C",satellite=19,path=datadir())
for (ii, dt) in enumerate(Date(2019,12,6) : Day(1) : Date(2026,2,28))

    if dt < Date(2024)
        ds = read(g16_CPS,geo,"PSD",dt,throw=false)
    elseif dt < g19_CPS.start
        ds = read(g16_CPS,geo,"CPS",dt,throw=false)
    else
        ds = read(g19_CPS,geo,"CPS",dt,throw=false)
    end
    if !isnothing(ds)
        close(ds)
    end

end