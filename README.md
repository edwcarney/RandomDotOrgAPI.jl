# RandomDotOrgAPI.jl

Julia module with functions to provide support for obtaining random numbers generated by the <a href="https://random.org">RANDOM.ORG (RDO)</a> website using the API. (See this <a href="https://api.random.org/api-keys">link</a> for information on obtaining an API key and some advantages of using the API.) The code is set up to use the 'basic' setting&mdash;an API key of all zeros.

Functions using HTTP are available in the following repository: https://github.com/edwcarney/RandomDotOrg.jl

From the RANDOM.ORG <a href="https://www.random.org/faq">FAQ (Q4.1)</a>:
<blockquote>The RANDOM.ORG setup uses an array of radios that pick up atmospheric noise. Each radio generates approximately 12,000 bits per second. The random bits produced by the radios are used as the raw material for all the different generators you see on RANDOM.ORG. Each time you use one of the generators, you spend some bits. By enforcing a limit on the number of bits you can use per day, the quota system prevents any one person from hogging all the numbers. (Believe us, this was a big problem before we implemented the quota system.)</blockquote>

# Current functions
<b>get_usage()</b>&mdash;obtain current bit quota for your IP<br>
<b>check_usage()</b>&mdash;check if quota is non-zero.<br>
<b>get_result()</b>&mdash;get a stored signed result from RDO (stored >= 24 hours)<br>
<b>verify_signature()</b>&mdash;obtain signature verification for a previously signed result from RDO<br>
<b>generate_integers()</b>&mdash;obtain integers<br>
<b>generate_integer_sequences()</b>&mdash;obtain randomized sequences of integers 1..N<br>
<b>generate_strings()</b>&mdash;obtain random strings of characters (upper/lower case letters, digits)<br>
<b>generate_gaussians()</b>&mdash;obtain random Gaussian numbers<br>
<b>generate_decimal_fractions()</b>&mdash;obtain random numbers on the interval (0,1)<br>
<b>generate_uuids()</b>&mdash;obtain random bytes in various formats<br>
<b>generate_blobs()</b>&mdash;generate bit blobs of sizes in multiples of 8 in base64 or hex<br>
<b>pull_data()</b>&mdash;extract data from RDO response (RDO returns Julia Dictionary)

Simply include the file with <b>include("RandomDotOrgAPI.jl")</b>. You may also install the module from GitHub using<br>
Pkg.add(url="https://github.com/edwcarney/RandomDotOrgAPI.jl") in the Julia REPL<br>
or use add "https://github.com/edwcarney/RandomDotOrgAPI.jl" in the Pkg REPL<br>

Values are returned in a Julia dictionary. Use the <b>pull_data</b> function to extract random values.

The use of secure HTTP by RANDOM.ORG prevents interception while the numbers are in transit. However, it is probably best not to use the Random.org site for any purpose that might have a direct impact on security. The FAQ (Q2.4) on the website says the following: "We should probably note that while fetching the numbers via secure HTTP would protect them from being observed while in transit, anyone genuinely concerned with security should not trust anyone else (including RANDOM.ORG) to generate their cryptographic keys."

using HTTP, JSON
