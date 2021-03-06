"""
    RandomDotOrgAPI

Use various functions from https://random.org (q.v.).

# Currently available
- getUsage(): obtain current bit quota for your IP.
- checkUsage(): check if quota is non-zero.
- getResult(): get a stored signed result from RDO (stored >= 24 hours)
- verifySignature(): obtain signature verification for a previously signed result from RDO
- generateIntegers(): obtain integers.
- generateIntegerSequences(): obtain randomized sequences of integers 1..N
- generateStrings(): obtain random strings of characters (upper/lower case letters, digits)
- generateGaussians(): obtain random Gaussian numbers
- generateDecimalFractions(): obtain random numbers on the interval (0,1)
- generateUUIDs(): obtain random bytes in various formats
- generateBlobs(): generate bit blobs of sizes in multiples of 8 in base64 or hex

Github repository at: https://github.com/edwcarney/RandomDotOrgAPI

"""
module RandomDotOrgAPI

using HTTP, JSON
# using OrderedCollections

const url = "https://api.random.org/json-rpc/2/invoke"
const myapikey = "00000000-0000-0000-0000-000000000000" # modify this variable with your own API key
const myapikeyzeros = "00000000-0000-0000-0000-000000000000"


export  getUsage, checkUsage, getResult, verifySignature, generateIntegers, generateIntegerSequences, generateStrings, generateGaussians,
        generateDecimalFractions, generateUUIDs, generateBlobs

"""
    Get the current bit quota from Random.org
"""
function getUsage(; apiType = "basic")
    getUsage1 = Dict(
        "jsonrpc" => "2.0",
        "method" => "getUsage",
        "params" => Dict(
            "apiKey" => myapikeyzeros
            ),
        "id" => 22407
    )

    if apiType == "signed"
         getUsage1["params"]["apiKey"] = myapikey
    end

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(getUsage1))
    out = JSON.parse(String(r.body))
    return out
end;

"""

checkUsage(minimum = 500::Number)

    Test for sufficient quota to insure response. This should be set to match
    user's needs.
"""
function checkUsage(minimum = 500::Number)

    return (getUsage()["result"]["bitsLeft"] >= minimum);
end;

"""
    getResult(serialnumber::Int)

"""
function getResult(serialNumber::Int)
    getResult = Dict(
        "jsonrpc" => "2.0",
        "method" => "getResult",
        "params" => Dict(
            "apiKey" => myapikey,
            "serialNumber" => serialNumber
        ),
        "id" => 22407
    )

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(getResult))
    out = JSON.parse(String(r.body))
    return out
end;

"""
    verifySignature(result::Dict)

Verify a signature from a previous signed request.

# Arguments
- `result` : Dict with signed result from RDO for previous request

# Example
```
r1 = getResult(672)
verifySignature(r1)
"result" => Dict{String,Any} with 1 entry:
    "authenticity" => true
```
"""
function verifySignature(result::Dict)
    verifSignature = Dict(
        "jsonrpc" => "2.0",
        "method" => "verifySignature",
        "params" => Dict(
            "random" => result["result"]["random"],
            "signature" => result["result"]["signature"]
        ),
        "id" => 22407
    )

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(verifSignature))
    out = JSON.parse(String(r.body))
    return out
end

"""
    generateIntegers(n = 100::Number, min = 1, max = 20, base = 10, parse=true, check = true, replace = true, apitype = "basic")

Get `n` random integers on the interval `[min, max]` as strings
in one of 4 `base` values--[binary (2), octal (8), decimal (10), or hexadecimal (16)]
All numbers, except base 10, are returned as strings.

# Arguments
- `max`,`min` : [-1e9, 1e9]
- `base::Integer`: retrieved Integer format [2, 8, 10, 16]
- `numeric`: return numbers instead of strings (base = 10, only)
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement
- `apiType::String`: "basic" or "signed"; key of zeros if "basic"

# Examples
```
generateIntegers(5, max=50, base=16)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3361463
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any["1d", "0f", "0b", "11", "1e"]
            "completionTime" => "2020-08-01 22:54:49Z"
    "advisoryDelay" => 3150
    "bitsUsed"      => 28
    "requestsLeft"  => 773473

julia> generateIntegers(5, max=4096, base=2, min=2048)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3363817
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any["110110110111", "100111010010", "111001100010", "111100100011", "110100101111"]
            "completionTime" => "2020-08-01 22:50:06Z"
    "advisoryDelay" => 3670
    "bitsUsed"      => 55
    "requestsLeft"  => 773569

julia> generateIntegers(5, max=200)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3362373
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any[168, 168, 4, 101, 175]
            "completionTime" => "2020-08-01 22:52:27Z"
    "advisoryDelay" => 2970
    "bitsUsed"      => 38
    "requestsLeft"  => 773510
```
"""
function generateIntegers(n = 100::Number; min = 1, max = 20, base = 10, numeric = true, check = true, replace=true, apiType="basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (min < -1f+09 || max > 1f+09 || min > max) && return "Range must be between -1e9 and 1e9"

    (!(base in [2, 8, 10, 16])) && return "Base has to be one of 2, 8, 10 or 16"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

#     urlbase = "https://www.random.org/integers/"
#     urltxt = @sprintf("%s?num=%d&min=%d&max=%d&col=%d&base=%d&format=plain&rnd=new",
#                     urlbase, n, Int(min), Int(max), col, base)
    genIntegers = Dict{String, Any}(
                "jsonrpc" => "2.0",
                "method" => "generateIntegers",
                "params" => Dict{String, Any}(
                        "n" => n,
                        "min" => min,
                        "max" => max,
                        "base" => base,
                        "replacement" => replace
                ),
                "id" => 22407
    )

    apiType=="basic" ? push!(genIntegers, "method" => "generateIntegers") : push!(genIntegers, "method" => "generateSignedIntegers")
    apiType=="basic" ? push!(genIntegers["params"], "apiKey" =>   myapikeyzeros) : push!(genIntegers["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genIntegers))
    out = JSON.parse(String(r.body))

    return out
end


"""
    generateIntegerSequences(n = 1; min = 1::Number, max = 20::Number, col = 1, check = true, replace=true, apiType="basic")

Get a randomized interval `[min, max]`. Returns (max - min + 1) randomized integers
All numbers are returned as strings (as Random.org sends them).

# Arguments
- `length` : size of the returned sequence; may be a tuple
- `min` : no less than 1; may be a tuple, as [1, 1]
- `max` : must be [-1e9, 1e9]; may be a tuple, as [69, 26]
- `base::Integer`: retrieved Integer format [2, 8, 10, 16]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement
- `apiType::String`: "basic" or "signed"; key of zeros, if "basic"

Returns a Dict with results in "result", data are nested in ["random"]["data"]. Multiple sequences
must be teased out with deeper slicing. For example, the first sequence in a two sequence return
will require the following: ["result"]["random"]["data"][1]

Additional information, such as the nuber of bits left in your quota will be provided. See this page for
further details on this function: https://api.random.org/json-rpc/2/basic

# Example of a simple sequence of random order of 1:10 with replace = false
```
julia> generateIntegerSequences(1, max=10)
"result"  => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3830058
        "random"        => Dict{String,Any} with 2 entries:
            "data"=>Any[Any[4, 6, 3, 2, 8, 1, 7, 10, 9, 5]],
            "completionTime"=>"2020-07-31 04:55:14Z"
    "advisoryDelay" => 2850 # recommended wait time for next request in ms
    "bitsUsed"      => 33
    "requestsLeft"  => 792944

 # Example of a multiple sequence from 1 to 10 and 1 to 5, with 10 samples from each with replace = true
 generateIntegerSequences(2, min = [1, 1],  max=[10, 5], replace=true)
"result"   => Dict{String,Any} with 5 entries:
    "bitsLeft"=>3825370,
        "random"  => Dict{String,Any} with 2 entries:
            "data"=>Any[Any[7, 2, 6, 1, 5, 3, 5, 2, 1, 9], Any[5, 3, 4, 2, 4, 3, 5, 1, 1, 4]],
            "completionTime"=>"2020-07-31 05:01:10Z"
    "advisoryDelay" => 2480
    "bitsUsed"      => 56
    "requestsLeft"  => 792747
```
"""
function generateIntegerSequences(n = 10::Number, length = 10::Number; min = 1::Number, max = 20::Number, base = 10, check = true, replace = true, apiType = "basic")
    # (min < -1f+09 || max > 1f+09 || min > max) && return "Range must be between -1e9 and 1e9"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genIntegerSequences = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "method" => "generateIntegerSequences",
        "params" => Dict{String, Any}(
                "n" => n,
                "length" => length,
                "min" => min,
                "max" => max,
                "base" => base,
                "replacement" => replace
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genIntegerSequences, "method" => "generateIntegerSequences") : push!(genIntegerSequences, "method" => "generateSignedIntegerSequences")
    apiType=="basic" ? push!(genIntegerSequences["params"], "apiKey" =>   myapikeyzeros) : push!(genIntegerSequences["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genIntegerSequences))
    out = JSON.parse(String(r.body))

    return out;
end

"""

    generateStrings(n=10::Number, length=5, characters="abcdefghijklmnopqrstuvwxyz"; check=true)

Get `n` random strings of length `len`

# Arguments
- `n::number` : number of strings
- `length::Number` : length of strings [1, 32]
- `characters::String`: strings formed from this set of characters
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement (strings might be duplicated)
- `apiType::String`: "basic" or "signed"; "basic" sends zeros as  myapikey

# Examples
```
# Generate 2 strings of 10 characters each from the lower case alphabet with replacement

generateStrings(2, 10, "abcdefghijklmnopqrstuvwxyz", apiType="basic")
"result"  => Dict{String,Any} with 5 entries:
    "bitsLeft"  => 3812394
        "random"    => Dict{String,Any} with 2 entries:
            "data"           => Any["crarvpazcz", "iagtbmseus"]
            "completionTime" => "2020-07-31 05:27:21Z"
    "advisoryDelay" => 1560
    "bitsUsed"      => 56
    "requestsLeft"  => 792218

# Generate a single string of 15 characters from the upper and lower case alphabets + numerals
# without replacement

generateStrings(1, 15, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; replace=false, apiType="basic")
"result"  => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3356382
    "random"        => Dict{String,Any} with 2 entries:
        "data"           => Any["BEuIiiYud34tGa6"]
        "completionTime" => "2020-08-01 23:00:07Z"
    "advisoryDelay" => 2740
    "bitsUsed"      => 89
    "requestsLeft"  => 773264
```
"""
function generateStrings(n = 10::Number, length = 5::Number, characters = "abcdefghijklmnopqrstuvwxyz"::String; check = true, replace = true, apiType="basic")
    (n < 1 || n > 10000) && return "1 to 10,000 requests only"

    (length < 1 || length > 32) && return "Length must be between 1 and 32"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genStrings = OrderedDict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "length" => length,
                "characters" => characters,
                "replacement" => replace
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genStrings, "method" => "generateStrings") : push!(genStrings, "method" => "generateSignedStrings")
    apiType=="basic" ? push!(genStrings["params"], "apiKey" =>   myapikeyzeros) : push!(genStrings["params"], "apiKey" =>  myapikey)

    @show JSON.json(genStrings)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genStrings))
    out = JSON.parse(String(r.body))

    return out;
end

"""

    generateGaussians(n = 10::Number, mean = 0.0, stdev = 1.0, digits = 10; check = true, replace = true, apiType = "basic")

Get n numbers from a Gaussian distribution with `mean` and `stdev`.
Returns strings in `dec` decimal places.
Scientific notation only for now.

# Arguments
- `mean`, `stdev` : between [-1e6, 1e6]
- `significantDigits` : decimal places [2,14]
- `check::Bool`: perform a call to `checkQuota` before making request


# Example requesting 500 Gaussians with mean = 5.0, stdev = 2.5, 10 significant digits
```
julia> generateGaussians(500, 5, 2.5, 10, apiType="basic")
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3784434
    "random"        => Dict{String,Any} with 2 entries:
                        "data"           => Any[3.45881, 0.466094, 5.20018, 6.11947, 0.843332, 5.51932, 4.23481, 0.0137821, -1.96319, 3.56091
                                                . . . 6.06737, 7.00533, 12.6734, 1.24946, 4.35043, 5.5967, 5.87513, 4.49188, -0.364909, 4.10236]
                        "completionTime" => "2020-07-31 06:01:50Z"
    "advisoryDelay" => 1990
    "bitsUsed"      => 16610
    "requestsLeft"  => 791750
```
"""
function generateGaussians(n = 10::Number, mean = 0.0, stdev = 1.0, digits = 10; check = true, apiType = "basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (mean < -1f+06 || mean > 1f+06) && return "Mean must be between -1e6 and 1e6"

    (stdev < -1f+06 || stdev > 1f+06) && return "Std dev must be between -1e6 and 1e6"

    (digits < 2 || digits > 14) && return "Decimal places must be between 2 and 14"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genGaussians = Dict{String, Any}(
                "jsonrpc" => "2.0",
                "params" => Dict{String, Any}(
                        "n" => n,
                        "mean" => mean,
                        "standardDeviation" => stdev,
                        "significantDigits" => digits
                ),
                "id" => 22407
    )

    apiType=="basic" ? push!(genGaussians, "method" => "generateGaussians") : push!(genGaussians, "method" => "generateSignedGaussians")
    apiType=="basic" ? push!(genGaussians["params"], "apiKey" =>   myapikeyzeros) : push!(genGaussians["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genGaussians))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generateDecimalFractions(n = 10::Number; digits = 5, check = true, replace = true)

Get n decimal fractions on the interval (0,1).
Returns strings in `digits` decimal places.

# Arguments
- `n`: number of fractions to generate
- `digits` : decimal places [1, 14]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: sample with replacement (duplicates possible)

# Example to obtain 5 decimal fractions on the interval [0, 1)
```
generateDecimalFractions(5, 10, replace=false)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3722130
    "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any[0.532242, 0.4899, 0.430238, 0.709279, 0.150412]
            "completionTime" => "2020-07-31 07:23:00Z"
    "advisoryDelay" => 2640
    "bitsUsed"      => 166
    "requestsLeft"  => 790030
```
"""
function generateDecimalFractions(n = 10, digits = 10; check=true, replace = true, apiType = "basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (digits < 1 || digits > 14) && return "Decimal places must be between 1 and 14"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genDecimalFractions = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "decimalPlaces" => digits,
                "replacement" => replace
        ),
        "id" => 22407
)

    apiType=="basic" ? push!(genDecimalFractions, "method" => "generateDecimalFractions") : push!(genDecimalFractions, "method" => "generateSignedDecimalFractions")
    apiType=="basic" ? push!(genDecimalFractions["params"], "apiKey" =>   myapikeyzeros) : push!(genDecimalFractions["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genDecimalFractions))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generateGaussians(n = 10::Number, mean = 0.0, stdev = 1.0, digits = 10; check = true, replace = true, apiType = "basic")

Get n numbers from a Gaussian distribution with `mean` and `stdev`.
Returns strings in `dec` decimal places.
Scientific notation only for now.

# Arguments
- `mean`, `stdev` : between [-1e6, 1e6]
- `significantDigits` : decimal places [2,14]
- `check::Bool`: perform a call to `checkQuota` before making request


# Example requesting 500 Gaussians with mean = 5.0, stdev = 2.5, 10 significant digits
```
generateGaussians(500, 5, 2.5, 10, apiType="basic")
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3784434
    "random"        => Dict{String,Any} with 2 entries:
                        "data"           => Any[3.45881, 0.466094, 5.20018, 6.11947, 0.843332, 5.51932, 4.23481, 0.0137821, -1.96319, 3.56091
                                                . . . 6.06737, 7.00533, 12.6734, 1.24946, 4.35043, 5.5967, 5.87513, 4.49188, -0.364909, 4.10236]
                        "completionTime" => "2020-07-31 06:01:50Z"
    "advisoryDelay" => 1990
    "bitsUsed"      => 16610
    "requestsLeft"  => 791750
```
"""
function generateGaussians(n = 10::Number, mean = 0.0, stdev = 1.0, digits = 10; check = true, apiType = "basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (mean < -1f+06 || mean > 1f+06) && return "Mean must be between -1e6 and 1e6"

    (stdev < -1f+06 || stdev > 1f+06) && return "Std dev must be between -1e6 and 1e6"

    (digits < 2 || digits > 14) && return "Decimal places must be between 2 and 14"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genGaussians = Dict{String, Any}(
                "jsonrpc" => "2.0",
                "params" => Dict{String, Any}(
                        "n" => n,
                        "mean" => mean,
                        "standardDeviation" => stdev,
                        "significantDigits" => digits
                ),
                "id" => 22407
    )

    apiType=="basic" ? push!(genGaussians, "method" => "generateGaussians") : push!(genGaussians, "method" => "generateSignedGaussians")
    apiType=="basic" ? push!(genGaussians["params"], "apiKey" =>   myapikeyzeros) : push!(genGaussians["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genGaussians))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generateUUIDs(n = 10::Number; check=true, apiType = "basic")

Get n UUIDs.
Returns n UUIDs as strings.

# Arguments
- `n`: number of fractions to generate
- `check::Bool`: perform a call to `checkQuota` before making request

# Example to obtain 1 UUIDs
```
generateUUIDs(1)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3396647
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any["12598e3a-c96a-4b16-bea4-b7d404717080"]
            "completionTime" => "2020-08-01 21:48:39Z"
    "advisoryDelay" => 3070
    "bitsUsed"      => 122
    "requestsLeft"  => 774929
```
"""
function generateUUIDs(n = 10::Number; check=true, apiType = "basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genUUIDs = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
        ),
        "id" => 22407
)

    apiType=="basic" ? push!(genUUIDs, "method" => "generateUUIDs") : push!(genUUIDs, "method" => "generateSignedUUIDs")
    apiType=="basic" ? push!(genUUIDs["params"], "apiKey" =>   myapikeyzeros) : push!(genUUIDs["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genUUIDs))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generateBlobs(n = 10::Number, size = 80; format = 'base64', check = true, apiType = "basic")

Get n Blobs.
Returns n Blobs as strings in format requested.

# Arguments
- `n`: number of fractions to generate
- `size` : size in bits (divisible by 8)
- `format` : "base64" [default] or "hex"
- `check::Bool`: perform a call to `checkQuota` before making request

# Example to obtain 1 UUIDs
```
generateBlobs(1)
Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3335873
    "random" => Dict{String,Any} with 2 entries:
        "data"           => Any["342ae094e29e9814ef21"]
        "completionTime" => "2020-08-03 21:14:38Z"
    "advisoryDelay" => 3650
    "bitsUsed"      => 32
    "requestsLeft"  => 774042
```
"""
function generateBlobs(n = 10::Number, size = 100; format = "base64", check=true, apiType = "basic")
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (size < 1 || size > 2^20) && return "Size must be between 1 and 1048576"

    (format != "base64" && format != "hex") && return "Format must be 'hex' or 'base64'"

    (check && !checkUsage()) && return "random.org suggests to wait until tomorrow"

    genBlobs = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "size" => size,
                "format" => format
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genBlobs, "method" => "generateBlobs") : push!(genBlobs, "method" => "generateSignedBlobs")
    apiType=="basic" ? push!(genBlobs["params"], "apiKey" =>   myapikeyzeros) : push!(genBlobs["params"], "apiKey" =>  myapikey)

    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genBlobs))
    out = JSON.parse(String(r.body))

    return out
end

end # module
