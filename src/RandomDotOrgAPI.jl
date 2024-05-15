"""
    RandomDotOrgAPI

Use various functions from https://random.org (q.v.).

# Currently available
- get_usage(): obtain current bit quota for your IP.
- check_usage(): check if quota is non-zero.
- get_result(): get a stored signed result from RDO (stored >= 24 hours)
- verify_signature(): obtain signature verification for a previously signed result from RDO
- generate_integers(): obtain integers.
- generate_integer_sequences(): obtain randomized sequences of integers 1..N
- generate_strings(): obtain random strings of characters (upper/lower case letters, digits)
- generate_gaussians(): obtain random Gaussian numbers
- generate_decimal_fractions(): obtain random numbers on the interval (0,1)
- generate_uuids(): obtain random bytes in various formats
- generate_blobs(): generate bit blobs of sizes in multiples of 8 in base64 or hex
- pull_data(): extract data from RDO response (Dictionary)

Github repository at: https://github.com/edwcarney/RandomDotOrgAPI

"""
module RandomDotOrgAPI

using HTTP, JSON
# using OrderedCollections

const url = "https://api.random.org/json-rpc/4/invoke"
# apiKeyFile = string(pwd(),"/","myapikey.jl")
# myapikey = "00000000-0000-0000-0000-000000000000"
# if isfile(apiKeyFile)
#     include(apiKeyFile)
# end

export  get_usage, check_usage, get_result, verify_signature, generate_integers, generate_integer_sequences, generate_strings, generate_gaussians,
        generate_decimal_fractions, generate_uuids, generate_blobs, pull_data

"""
    get_usage(apiKey)

Get the current bit quota from Random.org

# Argument
- `apiType::String`: "basic" or "signed"; key of zeros if "basic"

"""
function get_usage(; apiKey="00000000-0000-0000-0000-000000000000")

    get_usage1 = Dict(
        "jsonrpc" => "2.0",
        "method" => "getUsage",
        "params" => Dict(
            "apiKey" => apiKey
            ),
        "id" => 22407
    )

    # if apiType == "signed"
    #      get_usage1["params"]["apiKey"] = myapikey_signed;
    # end

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(get_usage1))
    out = JSON.parse(String(r.body))
    return out
end;

"""

    check_usage(minimum = 500; apiKey)

    Test for sufficient quota to insure response. This should be set to match
    user's needs.

# Arguments
- `minimum::Int`: minimum number of bits remaining required
- `apiType::String`: "basic" or "signed"; key of zeros if "basic"

"""
function check_usage(minimum = 500; apiKey="00000000-0000-0000-0000-000000000000")

    return (get_usage(apiKey=apiKey)["result"]["bitsLeft"] >= minimum);
end;

"""
    get_result(serialnumber, apikey)

    get a stored signed result from RDO (stored >= 24 hours)

"""
function get_result(serialNumber; apiKey = "00000000-0000-0000-0000-000000000000")

    get_result = Dict(
        "jsonrpc" => "2.0",
        "method" => "getResult",
        "params" => Dict(
            "apiKey" => apiKey,
            "serialNumber" => serialNumber
        ),
        "id" => 22407
    )

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(get_result))
    out = JSON.parse(String(r.body))
    return out
end;

"""
    verify_signature(result::Dict)

Verify a signature from a previous signed request.

# Arguments
- `result` : Dict with signed result from RDO for previous request

# Example
```
r1 = get_result(672)
verify_signature(r1)
"result" => Dict{String,Any} with 1 entry:
    "authenticity" => true
```
"""
function verify_signature(result::Dict)
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
    generate_integers(n = 100, min = 1, max = 20, base = 10, check = true, replace = true,
                    apitype = "basic", apiKey)

Get `n` random integers on the interval `[min, max]` as strings
in one of 4 `base` values--[binary (2), octal (8), decimal (10), or hexadecimal (16)]
All numbers, except base 10, are returned as strings.

# Arguments
- `max`,`min` : [-1e9, 1e9]
- `base`: retrieved Integer format [2, 8, 10, 16]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement
- `apiType::String`: "basic" or "signed"; key of zeros if "basic"

# Examples
```
generate_integers(5, max=50, base=16)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3361463
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any["1d", "0f", "0b", "11", "1e"]
            "completionTime" => "2020-08-01 22:54:49Z"
    "advisoryDelay" => 3150
    "bitsUsed"      => 28
    "requestsLeft"  => 773473

julia> generate_integers(5, max=4096, base=2, min=2048)
"result" => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3363817
        "random"        => Dict{String,Any} with 2 entries:
            "data"           => Any["110110110111", "100111010010", "111001100010", "111100100011", "110100101111"]
            "completionTime" => "2020-08-01 22:50:06Z"
    "advisoryDelay" => 3670
    "bitsUsed"      => 55
    "requestsLeft"  => 773569

julia> generate_integers(5, max=200)
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
function generate_integers(n = 100; min = 1, max = 20, base = 10, check = true, replace=true,
                            apiType="basic", apiKey="00000000-0000-0000-0000-000000000000")
    
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (min < -1f+09 || max > 1f+09 || min > max) && return "Range must be between -1e9 and 1e9"

    (!(base in [2, 8, 10, 16])) && return "Base has to be one of 2, 8, 10 or 16"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genIntegers = Dict{String, Any}(
                "jsonrpc" => "2.0",
                "method" => "generate_integers",
                "params" => Dict{String, Any}(
                        "n" => n,
                        "min" => min,
                        "max" => max,
                        "base" => base,
                        "replacement" => replace,
                        "apiKey" =>   apiKey
                ),
                "id" => 22407
    )

    apiType=="basic" ? push!(genIntegers, "method" => "generateIntegers") : push!(genIntegers, "method" => "generateSignedIntegers")

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genIntegers))
    out = JSON.parse(String(r.body))

    return out
end


"""
    generate_integer_sequences(n = 1; length = 10, min = 1, max = 20, base=10, check = true, replace=true,
                                apiType="basic", apiKey="00000000-0000-0000-0000-000000000000")

Get a randomized interval `[min, max]`. Returns (max - min + 1) randomized integers
All numbers are returned as strings (as Random.org sends them).

# Arguments
- `n` : number of sequences
- `length` : size of the returned sequence; may be a tuple
- `min` : no less than 1; may be a tuple, as [1, 1]
- `max` : must be [-1e9, 1e9]; may be a tuple, as [69, 26]
- `base`: retrieved Integer format [2, 8, 10, 16]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement
- `apiType::String`: "basic" or "signed"
- `apiKey::String`: "00000000-0000-0000-0000-000000000000"

Returns a Dict with results in "result", data are nested in ["random"]["data"]. Multiple sequences
must be teased out with deeper slicing. For example, the first sequence in a two sequence return
will require the following: ["result"]["random"]["data"][1]

Additional information, such as the nuber of bits left in your quota will be provided. See this page for
further details on this function: https://api.random.org/json-rpc/2/basic

# Example of a simple sequence of random order of 1:10 with replace = false
```
julia> generate_integer_sequences(1, max=10)
"result"  => Dict{String,Any} with 5 entries:
    "bitsLeft"      => 3830058
        "random"        => Dict{String,Any} with 2 entries:
            "data"=>Any[Any[4, 6, 3, 2, 8, 1, 7, 10, 9, 5]],
            "completionTime"=>"2020-07-31 04:55:14Z"
    "advisoryDelay" => 2850 # recommended wait time for next request in ms
    "bitsUsed"      => 33
    "requestsLeft"  => 792944

 # Example of a multiple sequence from 1 to 10 and 1 to 5, with 10 samples from each with replace = true
 generate_integer_sequences(2, min = [1, 1],  max=[10, 5], replace=true)
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
function generate_integer_sequences(n = 10, length = 10; min = 1, max = 20, base = 10, check = true, replace = true,
                                    apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

    (length > (min - (max + 1))) && return "Length must be less than 10000"
    
    (min < -1f+09 || max > 1f+09 || min > max) && return "Range must be between -1e9 and 1e9"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genIntegerSequences = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "method" => "genIntegerSequences",
        "params" => Dict{String, Any}(
                "n" => n,
                "length" => length,
                "min" => min,
                "max" => max,
                "base" => base,
                "replacement" => replace,
                "apiKey" => apiKey
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genIntegerSequences, "method" => "generate_integer_sequences") : push!(genIntegerSequences, "method" => "generateSignedIntegerSequences")

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genIntegerSequences))
    out = JSON.parse(String(r.body))

    return out;
end

"""

    generate_strings(n=10, length=5, characters="abcdefghijklmnopqrstuvwxyz"; check=true, replace=false,
                    apiType='basic', apiKey="00000000-0000-0000-0000-000000000000")

Get `n` random strings of length `len`

# Arguments
- `n` : number of strings
- `length` : length of strings [1, 32]
- `characters::String`: strings formed from this set of characters
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement (strings might be duplicated)
- `apiType::String`: "basic" or "signed"
- `apiKey::String`: "00000000-0000-0000-0000-000000000000"

# Examples
```
# Generate 2 strings of 10 characters each from the lower case alphabet with replacement

generate_strings(2, 10, "abcdefghijklmnopqrstuvwxyz", apiType="basic")
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

generate_strings(1, 15, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; replace=false, apiType="basic")
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
function generate_strings(n = 10, length = 5, characters = "abcdefghijklmnopqrstuvwxyz"::String; check = true, replace = true,
    apiType="basic", apiKey="00000000-0000-0000-0000-000000000000")
    
    (n < 1 || n > 10000) && return "1 to 10,000 requests only"

    (length < 1 || length > 32) && return "Length must be between 1 and 32"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genStrings = OrderedDict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "length" => length,
                "characters" => characters,
                "replacement" => replace,
                "apiKey" =>   apiKey
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genStrings, "method" => "generateStrings") : push!(genStrings, "method" => "generateSignedStrings")

    @show JSON.json(genStrings)

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genStrings))
    out = JSON.parse(String(r.body))

    return out;
end

"""

    generate_gaussians(n = 10, mean = 0.0, stdev = 1.0, digits = 10; check = true, replace = true,
                        apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

Get n numbers from a Gaussian distribution with `mean` and `stdev`.
Returns strings in `dec` decimal places.
Scientific notation only for now.

# Arguments
- `n` : number of gaussian values (1 - 10000)
- `mean`, `stdev` : between [-1e6, 1e6]
- `digits` : decimal places [2,14]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: use sampling with replacement (strings might be duplicated)
- `apiType::String`: "basic" or "signed"; "basic" sends zeros as  myapikey

# Example requesting 500 Gaussians with mean = 5.0, stdev = 2.5, 10 significant digits
```
julia> generate_gaussians(500, 5, 2.5, 10, apiType="basic")
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
function generate_gaussians(n = 10, mean = 0.0, stdev = 1.0, digits = 10; check = true,
                            apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (mean < -1f+06 || mean > 1f+06) && return "Mean must be between -1e6 and 1e6"

    (stdev < -1f+06 || stdev > 1f+06) && return "Std dev must be between -1e6 and 1e6"

    (digits < 2 || digits > 14) && return "Decimal places must be between 2 and 14"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genGaussians = Dict{String, Any}(
                "jsonrpc" => "2.0",
                "params" => Dict{String, Any}(
                        "n" => n,
                        "mean" => mean,
                        "standardDeviation" => stdev,
                        "significantDigits" => digits,
                        "apiKey" =>   apiKey
                ),
                "id" => 22407
    )

    apiType=="basic" ? push!(genGaussians, "method" => "generateGaussians") : push!(genGaussians, "method" => "generateSignedGaussians")

    r = HTTP.request("POST", url,
                ["Content-Type" => "application/json"],
                JSON.json(genGaussians))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generate_decimal_fractions(n = 10; digits = 5, check = true, replace = true, apiType, apiKey)

Get n decimal fractions on the interval (0,1).
Returns strings in `digits` decimal places.

# Arguments
- `n`: number of fractions to generate
- `digits` : decimal places [1, 14]
- `check::Bool`: perform a call to `checkQuota` before making request
- `replace::Bool`: sample with replacement (duplicates possible)

# Example to obtain 5 decimal fractions on the interval [0, 1)
```
generate_decimal_fractions(5, 10, replace=false)
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
function generate_decimal_fractions(n = 10, digits = 10; check=true, replace = true,
                                    apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")
 
    (n < 1 || n > 10000) && return "Requests must be between 1 and 10,000 numbers"

    (digits < 1 || digits > 14) && return "Decimal places must be between 1 and 14"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genDecimalFractions = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "decimalPlaces" => digits,
                "replacement" => replace,
                "apiKey" =>   apiKey
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genDecimalFractions, "method" => "generateDecimalFractions") : push!(genDecimalFractions, "method" => "generateSignedDecimalFractions")   # apiType=="basic" ? push!(genDecimalFractions["params"], "apiKey" =>   myapikey) : push!(genDecimalFractions["params"], "apiKey" =>  myapikey_signed)

    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genDecimalFractions))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generate_uuids(n = 10; check=true, apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

Get n UUIDs.
Returns n UUIDs as strings.

# Arguments
- `n`: number of UUIDs to generate
- `check::Bool`: perform a call to `checkQuota` before making request

# Example to obtain 1 UUIDs
```
generate_uuids(1)
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
function generate_uuids(n = 10; check=true, apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

    (n < 1 || n > 1000) && return "Requests must be between 1 and 1000 numbers"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genUUIDs = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "apiKey" =>   apiKey
        ),
        "id" => 22407
)

    apiType=="basic" ? push!(genUUIDs, "method" => "generateUUIDs") : push!(genUUIDs, "method" => "generateSignedUUIDs")
    
    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genUUIDs))
    out = JSON.parse(String(r.body))

    return out
end

"""
    generate_blobs(n = 10, size = 80; format = 'base64', check = true,
                    apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

Get n Blobs.
Returns n Blobs as strings in format requested.

# Arguments
- `n`: number of blobs   to generate
- `size` : size in bits (divisible by 8)
- `format` : "base64" [default] or "hex"
- `check::Bool`: perform a call to `checkQuota` before making request

# Example to obtain 1 UUIDs
```
generate_blobs(1)
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
function generate_blobs(n = 10, size = 100; format = "base64", check=true,
                        apiType = "basic", apiKey="00000000-0000-0000-0000-000000000000")

    (n < 1 || n > 100) && return "Requests must be between 1 and 100 numbers"

    (size < 1 || size > 2^20) && return "Size must be between 1 and 1048576"

    (mod(size,8) > 0) && return "Size must be evenly divisible by 8" 

    (format != "base64" && format != "hex") && return "Format must be 'hex' or 'base64'"

    (check && !check_usage()) && return "random.org suggests to wait until tomorrow"

    genBlobs = Dict{String, Any}(
        "jsonrpc" => "2.0",
        "params" => Dict{String, Any}(
                "n" => n,
                "size" => size,
                "format" => format,
                "apiKey" => apiKey
        ),
        "id" => 22407
    )

    apiType=="basic" ? push!(genBlobs, "method" => "generateBlobs") : push!(genBlobs, "method" => "generateSignedBlobs")

    r = HTTP.request("POST", url,
            ["Content-Type" => "application/json"],
            JSON.json(genBlobs))
    out = JSON.parse(String(r.body))

    return out
end

"""
    pull_data(RDOresp)

Extract data from RDO response (Dictionary)
Returns numerical data in form of Vector{Real}
Otherwise, returns vector of data

# Arguments
- `RDOresp`: response from RDO in form of dictionary
"""
function pull_data(RDOresp)
    if "random" in keys(RDOresp["result"])
        dataval = RDOresp["result"]["random"]["data"]
        if isa(dataval[1], Number)
            return convert(Vector{Real},dataval)
        elseif isa(dataval[1], Vector{Any})
            if isa(dataval[1][1], Number)
                return [[convert(Real, x) for x in y] for y in dataval]
            else
                return dataval
            end
        else
            return dataval
        end
    else
        dataval = RDOresp["result"]["bitsLeft"]
        return dataval
    end
end

end; # module
