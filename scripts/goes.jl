using DrWatson
@quickactivate "STRIde"

using Dates
using Logging
using Printf
using AWS, AWSS3

aws = AWSConfig(; creds=nothing, region="us-east-1")

bucket = "noaa-goes16"
product = "ABI-L2-ACMC"   # Cloud & Moisture Imagery - Full Disk
year = 2020

for day in 180 : 187, hour in 0 : 23

    prefix = "$product/$year/$(@sprintf("%03d", day))/$(@sprintf("%02d", hour))/"
    ymd = Dates.format(Date(year,1,1) + Day(day - 1),dateformat"yyyymmdd")
    ymdh = "$(ymd)$(@sprintf("%02d", hour))"
    mkpath(datadir("goes",product,ymdh))

    for (ii, obj) in enumerate(keys)
        s3_get_file(
            aws, bucket, obj["Key"],
            datadir(
                "goes",product,ymdh,
                "time$(@sprintf("%02d", ii)).nc"
            )
        )
    end

end