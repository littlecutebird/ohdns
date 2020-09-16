# OhDNS

## Warning
Don't use this to do dark things.

## How it works
A wrapper does subdomain enumeration with:
* Subfinder
* Amass
* Massdns
* GoWC - Wildcard cleaner. From [GoWC](https://github.com/sting8k/GoWC)

## Requirements

```
Nothing
```

## Usage
```
./ohdns.sh --help


 ██████╗ ██╗  ██╗██████╗ ███╗   ██╗███████╗
██╔═══██╗██║  ██║██╔══██╗████╗  ██║██╔════╝
██║   ██║███████║██║  ██║██╔██╗ ██║███████╗
██║   ██║██╔══██║██║  ██║██║╚██╗██║╚════██║
╚██████╔╝██║  ██║██████╔╝██║ ╚████║███████║
 ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═══╝╚══════╝
				OhDNS v1.0

Very fast & accurate dns resolving and bruteforcing.

OhDNS v1.0
Use subfinder, amass, and massdns to accurately resolve a large amount of subdomains and extract wildcard domains.

Usage:
	ohdns -wl wordlist.txt -d domain.com -w output.txt

	Example:
		ohdns [args] [--skip-wildcard-check] [--help] -wl wordlist.txt -d domain.com

	Optional:

		-d, --domain <domain>	Target to scan
		-wl, --wordlist	<filename>	Wordlist to do bruteforce
		-sc, --subfinder-config	<filename>	SubFinder config file
		-ac, --amass-config	<filename>	Amass config file
		-i, --ips	Show ips in output
		-sw, --skip-wildcard-check		Do no perform wildcard detection and filtering

		-w,  --write <filename>			Write valid domains to a file
		-wm, --write-massdns <filename>		Write massdns results to a file
		-ww, --write-wildcards <filename>	Write wildcard root subdomains to a file
		-wa, --write-answers <filename>		Write wildcard DNS answers to a file

		-h, --help				Display this message
```

## Example
```
./ohdns.sh -wl sub_wordlist.txt -d example.com -w output.txt -i


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

```
cat output.txt
...
partner-service.<example.com> 	 [x.x.65.172]
partner-service-testing.<example.com> 	 [x.x.65.172]
partner.<example.com> 	 [edge-web.dual-gslb.<example.com>.]
partners.<example.com> 	 [edge-web.dual-gslb.<example.com>.]
partners.wg.<example.com> 	 [edge-web.dual-gslb.<example.com>.]
payment-callback.<example.com> 	 [x.x.65.172]
pci.<example.com> 	 [x.x.36.21 x.x.34.21 x.x.32.21 x.x.38.21]
pci-testing.<example.com> 	 [x.x.36.21 x.x.34.21 x.x.38.21 x.x.32.21]
...

```

