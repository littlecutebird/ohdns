# OhDNS

## Warning
Don't use this to do dark things.

## How it works
A wrapper does subdomain enumeration with:
* Subfinder
* Amass
* Massdns
* Wildcard cleaner (modified). Fork from [puredns](https://github.com/d3mondev/puredns)

## Usage
```
./ohdns.sh -wl sub_wordlist.txt -d example.com -w output.txt


 ██████╗ ██╗  ██╗██████╗ ███╗   ██╗███████╗
██╔═══██╗██║  ██║██╔══██╗████╗  ██║██╔════╝
██║   ██║███████║██║  ██║██╔██╗ ██║███████╗
██║   ██║██╔══██║██║  ██║██║╚██╗██║╚════██║
╚██████╔╝██║  ██║██████╔╝██║ ╚████║███████║
 ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═══╝╚══════╝
                                ohdns v1.0

Very fast & accurate dns resolving and bruteforcing.

[!] Tempdir: /tmp/ohdns.RLuPqJ0r
[*] [SubFinder] Running ...
[!] [SubFinder] Finished | Duration: 8s
[*] [Amass] Running ...
[!] [Amass] Finished | Duration: 219s
[*] Merging wordlist ...
[*] Preparing list of domains for massdns...
[*] Sanitizing list...
[!] 137166 domains to resolve with massdns
[*] [MassDNS] Invoking massdns... this can take some time
[*] [MassDNS] Running the 1st time ...
[!] [MassDNS] Finished | Duration: 102s
[*] [MassDNS] Running the 2nd time ...
[!] [MassDNS] Finished | Duration: 60s
[*] [MassDNS] Merging output from 2 times.
[!] [MassDNS] 367 domains returned a DNS answer
[*] Detecting wildcard root subdomains...
[!] 0 wildcard root subdomains found
[!] Found 367 valid domains!
[*] Saving output to output.txt

[!] Found 367 valid domains in 6m43s

```

