using DrWatson
@quickactivate "STRIde"

using DelimitedFiles, Printf
using AWS, AWSS3
using GOES

aws = AWSConfig(; creds=nothing, region="us-east-1")
goeslist = readdlm(srcdir("goes.csv"), ',',comments=true)[1:50,:]
sID = goeslist[:,1]
dslist = goeslist[:,2]; nds = length(dslist)
startvec = Vector{Date}(undef,nds)
stopvec  = Vector{Date}(undef,nds)

for (ii, ds) in enumerate(dslist)

    @info "$(now()): Finding the start and end dates for GOES-$(sID[ii]) Dataset $(ds)"

    gds = GOESDataset(ID=sID[ii],product=String(ds),path=datadir())
    dt = Date(2017)
    jj = 0
    while jj < 1
        dt += Day(1)
        yr = year(dt)
        doy = dayofyear(dt)
        prefix = "$(gds.product)/$yr/$(@sprintf("%03d",doy))/00/"
        keys = s3_list_objects(aws,gds.bucket,prefix)
        for (kk, obj) in enumerate(keys)
            fnc = GOES.gdsfnc(gds,dt,0,kk)
            fol = dirname(fnc); if !isdir(fol); mkpath(fol) end
            if iszero(jj)
                jj += 1
                s3_get_file(aws,gds.bucket,obj["Key"],fnc)
                startvec[ii] = dt
            end
        end
    end

    dt = Date(2026,12,31)
    jj = 0
    while jj < 1
        dt -= Day(1)
        yr = year(dt)
        doy = dayofyear(dt)
        prefix = "$(gds.product)/$yr/$(@sprintf("%03d",doy))/00/"
        keys = s3_list_objects(aws,gds.bucket,prefix)
        for (kk, obj) in enumerate(keys)
            fnc = GOES.gdsfnc(gds,dt,0,kk)
            fol = dirname(fnc); if !isdir(fol); mkpath(fol) end
            if iszero(jj)
                jj += 1
                s3_get_file(aws,gds.bucket,obj["Key"],fnc)
                stopvec[ii] = dt
            end
        end
    end

end

@info stopvec
mat = cat(sID, dslist, startvec, stopvec, dims=2)

open(srcdir("goes_info.csv"), "w") do io
    writedlm(io, mat, ',')
end