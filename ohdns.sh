#!/bin/bash

program_name="OhDNS"
program_version="v1.0"
program_description="Very fast & accurate dns resolving and bruteforcing."

CURRENT_DIR=$(pwd)
AMASS_BIN="${CURRENT_DIR}/amass/amass"
SUBFINDER_BIN="${CURRENT_DIR}/subfinder/subfinder"
MASSDNS_BIN="${CURRENT_DIR}/massdns/massdns"
GOWC_BIN="${CURRENT_DIR}/gowc/gowc"
COL_LOGO='\033[0;36m'
COL_PROGNAME='\033[1;32m'
COL_PROGVERS='\033[0;36m'
COL_PROGDESC='\033[1;37m'
COL_META='\033[1;37m'
COL_MESSAGE='\033[0;36m'
COL_MESSAGE_TEXT='\033[0;37m'
COL_SUCCESS='\033[1;32m'
COL_SUCCESS_TEXT='\033[0;37m'
COL_ERROR='\033[0;31m'
COL_ERROR_TEXT='\033[0;37m'
COL_TEXT='\033[1;37m'
COL_PV='\033[1;30m'
COL_RESET='\033[0m'

help() {
	echo "OhDNS v1.0"
	echo "Use subfinder, amass, and massdns to accurately resolve a large amount of subdomains and extract wildcard domains."
	echo ""
	usage
}

usage() {
	echo "Usage:"
	echo "	ohdns -wl wordlist.txt -d domain.com -w output.txt"
	echo ""
	echo "	Example:"
	echo "		ohdns [args] [--skip-wildcard-check] [--help] -wl wordlist.txt -d domain.com"
	echo ""
	echo "	Optional:"
	echo ""
	echo "		-d, --domain <domain>	Target to scan"
	echo "		-wl, --wordlist	<filename>	Wordlist to do bruteforce"
	echo "		-sc, --subfinder-config	<filename>	SubFinder config file"
	echo "		-ac, --amass-config	<filename>	Amass config file"
	echo "		-i, --ips	Show ips in output"
	echo "		-sw, --skip-wildcard-check		Do no perform wildcard detection and filtering"
	echo ""
	echo "		-w,  --write <filename>			Write valid domains to a file"
	echo "		-wm, --write-massdns <filename>		Write massdns results to a file"
	echo "		-ww, --write-wildcards <filename>	Write wildcard root subdomains to a file"
	echo "		-wa, --write-answers <filename>		Write wildcard DNS answers to a file"
	echo ""
	echo "		-h, --help				Display this message"
}

print_header() {
	printf "${COL_LOGO}" >&2
	printf "

 ██████╗ ██╗  ██╗██████╗ ███╗   ██╗███████╗
██╔═══██╗██║  ██║██╔══██╗████╗  ██║██╔════╝
██║   ██║███████║██║  ██║██╔██╗ ██║███████╗
██║   ██║██╔══██║██║  ██║██║╚██╗██║╚════██║
╚██████╔╝██║  ██║██████╔╝██║ ╚████║███████║
 ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═══╝╚══════╝
"
	printf "				${COL_PROGNAME}${program_name} ${COL_PROGVERS}${program_version}\n" >&2
	printf '\n' >&2
	printf "${COL_PROGDESC}${program_description}\n" >&2
	printf "${COL_RESET}\n" >&2
}

log_message() {
	printf "${COL_META}[${COL_MESSAGE}*${COL_META}] ${COL_MESSAGE_TEXT}$1${COL_RESET}\n" >&2
}

log_success() {
	printf "${COL_META}[${COL_SUCCESS}!${COL_META}] ${COL_SUCCESS_TEXT}$1${COL_RESET}\n" >&2
}

log_error() {
	printf "${COL_META}[${COL_ERROR}X${COL_META}] ${COL_ERROR_TEXT}$1${COL_RESET}\n" >&2
}

domain_count() {
	
	if [[ $ips -eq 1 ]]; then
		echo "$(cat "${domains_withip}" | wc -l)" 2>/dev/null
	else
		echo "$(cat "${domains_work}" | wc -l)" 2>/dev/null
	fi
	
}

wildcard_count() {
	echo "$(cat "${wildcards_work}" | wc -l)" 2>/dev/null
}

parse_args() {
	
	resolvers_file="$(dirname $0)/resolvers.txt"
	resolvers_trusted_file="$(dirname $0)/trusted.txt"

	limit_rate=0
	limit_rate_trusted=0

	skip_validation=0
	skip_wildcard_check=0
	skip_sanitize=0

	domains_file=''
	massdns_file=''
	amass_config=''
	subfinder_config=''
	wildcards_file=''
	wildcard_answers_file=''
	ips=0

	resolvers_trusted_file="${CURRENT_DIR}/trusted.txt"
	resolvers_file="${CURRENT_DIR}/trusted.txt"
	skip_validation=1
	mode=1

	set +u
	while :; do
		case $1 in
			--domain|-d)
				domain=$2
				shift
				;;
			--wordlist|-wl)
				wordlist_file=$2
				shift
				;;
			--amass-config|-ac)
				amass_config=$2
				shift
				;;
			--subfinder-config|-sc)
				subfinder_config=$2
				shift
				;;
			--ips|-i)
				ips=1
				;;
			--skip-wildcard-check|-sw)
				skip_wildcard_check=1
				;;
			--write|-w)
				domains_file=$2
				shift
				;;
			--write-massdns|-wm)
				massdns_file=$2
				shift
				;;
			--write-wildcard-answers|-wa)
				wildcard_answers_file=$2
				shift
				;;
			--write-wildcards|-ww)
				wildcards_file=$2
				shift
				;;
			--help|-h)
				help
				exit 0
				;;
			"")
				break
				;;
			*)
				usage
				echo ""
				echo "Error: unknown argument: $1"
				exit 1
				;;
		esac
		shift
	done

	if [[ -z "${mode}" ]]; then
		usage
		echo ""
		echo "Error: no command given"
		exit 1
	fi

	if [[ ! -f "${resolvers_file}" ]]; then
		echo "Error: unable to open resolvers file ${resolvers_file}"
		echo ""
		exit 1
	fi

	if [[ ! -z "${amass_config}" ]]; then
		if [[ ! -f "${amass_config}" ]]; then
			echo ""
			echo "Error: Cannot open Amass-config file"
			exit 1
		fi
	fi

	if [[ ! -z "${subfinder_config}" ]]; then
		if [[ ! -f "${subfinder_config}" ]]; then
			echo ""
			echo "Error: Cannot open Subfinder-config file"
			exit 1
		fi
	fi


	if [[ "${mode}" -eq 1 ]]; then
		if [[ -z "${wordlist_file}" ]]; then
			usage
			echo ""
			echo "Error: no wordlist specified"
			exit 1
		fi

		if [[ ! -f "${wordlist_file}" ]]; then
			echo "Error: unable to open wordlist file ${wordlist_file}"
			echo ""
			exit 1
		fi

		if [[ -z "${domain}" ]]; then
			usage
			echo ""
			echo "Error: no domain specified"
			exit 1
		fi
	fi

	set -u
}

check_requirements() {
	# massdns
	"${MASSDNS_BIN}" --help > /dev/null 2>&1
	if [[ ! $? -eq 0 ]]; then
		echo "Error: unable to execute massdns."
		echo ""
		exit 1
	fi

	# wildcarder
	$(dirname $0)/wildcarder --version > /dev/null 2>&1
	if [[ ! $? -eq 0 ]]; then
		echo "Error: unable to execute wildcarder. Make sure it is present and that the requirements have been installed."
		echo ""
		echo "This might help: pip install -r requirements.txt"
		exit 1
	fi
}

init() {
	tempdir="$(mktemp -d -t ohdns.XXXXXXXX)"
	log_success "Tempdir: ${tempdir}"
	domains_work="${tempdir}/domains.txt"
	massdns_work="${tempdir}/massdns.txt"
	gowc_work="${tempdir}/gowc.txt"
	tempfile_work="${tempdir}/tempfile.txt"
	domains_withip="${tempdir}/domains_withip.txt"

}

prepare_domains_list() {
	log_message "Preparing list of domains for massdns..."
	if [[ "${mode}" -eq 1 ]]; then
		sed -E "s/^(.*)$/\\1.${domain}/" "${OUTPUT_TO_BE_RESOLVED}" > "${domains_work}"
	fi

	if [[ "${skip_sanitize}" -eq 0 ]]; then
		log_message "Sanitizing list..."

		# Set all to lowercase
		cat "${domains_work}" | tr '[:upper:]' '[:lower:]' > "${tempfile_work}"
		cp "${tempfile_work}" "${domains_work}"

		# Keep only valid characters
		cat "${domains_work}" | grep -o '^[a-z0-9\.\-]*$' > "${tempfile_work}"
		cp "${tempfile_work}" "${domains_work}"
	fi
	counted=$(cat "${domains_work}" | wc -l)
	log_success "${counted} domains to resolve with massdns"
}

massdns_trusted() {
	local domainfile=$1
	local domains_outputfile=$2
	local massdns_outputfile=$3

	invoke_massdns "${domainfile}" "${resolvers_trusted_file}" "${domains_outputfile}" "${massdns_outputfile}"
}

invoke_massdns() {
	local domains_file=$1
	local resolvers=$2
	local domains_outputfile=$3
	local massdns_outputfile=$4

	local count="$(cat "${domains_file}" | wc -l)"

	"${MASSDNS_BIN}" -q -r "${resolvers}" -o S -t A -w "${massdns_outputfile}" --retry SERVFAIL "${domains_file}"
	cat "${massdns_outputfile}" | awk -F '. ' '{ print $1 }' | sort -u > "${domains_outputfile}"

}

invoke_subfinder() {
	log_message "[SubFinder] Running ..."
	start=`date +%s`
	if [[ ! -z "${subfinder_config}" ]]; then
		"${SUBFINDER_BIN}" -d ${domain} -o "${tempdir}/subfinder_output.txt"  -config ${subfinder_config} > /dev/null 2>&1
	else
		"${SUBFINDER_BIN}" -d ${domain} -o "${tempdir}/subfinder_output.txt" > /dev/null 2>&1
	fi
	end=`date +%s`
	runtime=$((end-start))
	log_success "[SubFinder] Finished | Duration: ${runtime}s"
}

invoke_amass() {
	log_message "[Amass] Running ..."
	start=`date +%s`
	if [[ ! -z "${amass_config}" ]]; then
		"${AMASS_BIN}" enum --passive -nolocaldb -norecursive -noalts -d ${domain} -o "${tempdir}/amass_output.txt" -config ${amass_config} -timeout 8 -exclude "Brute Forcing" > /dev/null 2>&1
	else
		"${AMASS_BIN}" enum --passive -nolocaldb -norecursive -noalts -d ${domain} -o "${tempdir}/amass_output.txt" -timeout 8 -exclude "Brute Forcing" > /dev/null 2>&1
	fi
	end=`date +%s`
	runtime=$((end-start))
	log_success "[Amass] Finished | Duration: ${runtime}s"
}

merge_wordlist() {
	OUTPUT_TO_BE_RESOLVED="${tempdir}/toberesolved.txt"
	log_message "Merging wordlist ..."
	sed -i "s/\.${domain}$//g" "${tempdir}/subfinder_output.txt"
	sed -i "s/\.${domain}$//g" "${tempdir}/amass_output.txt"
	cat "${tempdir}/subfinder_output.txt" "${tempdir}/amass_output.txt" ${wordlist_file} | sort -u > ${OUTPUT_TO_BE_RESOLVED}
}

massdns_resolve() {
	local tmp_massdns_work1="${tempdir}/massdns_tmp1.txt"
	local tmp_massdns_work2="${tempdir}/massdns_tmp2.txt"
	local tmp_massdns_domain_work1="${tempdir}/domain_work_tmp1.txt"
	local tmp_massdns_domain_work2="${tempdir}/domain_work_tmp2.txt"
	log_message "[MassDNS] Invoking massdns... this can take some time"
	log_message "[MassDNS] Running the 1st time ..."
	start=`date +%s`
	massdns_trusted "${domains_work}" "${tmp_massdns_domain_work1}" "${tmp_massdns_work1}"
	end=`date +%s`
	runtime=$((end-start))
	log_success "[MassDNS] Finished | Duration: ${runtime}s"

	start=`date +%s`
	log_message "[MassDNS] Running the 2nd time ..."
	massdns_trusted "${domains_work}" "${tmp_massdns_domain_work2}" "${tmp_massdns_work2}"
	end=`date +%s`
	runtime=$((end-start))
	log_success "[MassDNS] Finished | Duration: ${runtime}s"
	

	log_message "[MassDNS] Merging output from 2 times."
	cat "${tmp_massdns_work2}" "${tmp_massdns_work1}" | sort -u > "${massdns_work}"
	cat "${tmp_massdns_domain_work1}" "${tmp_massdns_domain_work2}" | sort -u > "${domains_work}"
	

	if [[ $ips -eq 1 ]]; then
		cat "${massdns_work}" | awk '{ group[$1] = (group[$1] == "" ? $3 : group[$1] OFS $3 ) } END { for (group_name in group) {x=group_name;gsub(/\.$/,"",x); print x, "\t","["group[group_name]"]"}}' | sort -u > "${domains_withip}"
	fi

	log_success "[MassDNS] $(domain_count) domains returned a DNS answer"
}

cleanup_wildcards() {
	log_message "[GoWC] Cleaning wildcard root subdomains..."

	if [[ $ips -eq 1 ]]; then
		"${GOWC_BIN}" -m "${massdns_work}" -d ${domain} -o "${domains_withip}" -t 10 -i
	else
		"${GOWC_BIN}" -m "${massdns_work}" -d ${domain} -o "${domains_work}" -t 10 
	fi
}

write_output_files() {
	log_message "Saving output to ${domains_file}"
	echo "" >&2
	output_file="${domains_work}"
	if [[ $ips -eq 1 ]]; then
		output_file="${domains_withip}"
	fi


	if [[ -n "${domains_file}" ]]; then
		cp "${output_file}" "${domains_file}"
	else
		cat ${output_file}
	fi

	if [[ -n "${massdns_file}" ]]; then
		cp "${massdns_work}" "${massdns_file}"
	fi
}

cleanup() {
	debug=0
	if [[ "${debug}" -eq 1 ]]; then
		echo "" >&2
		echo "Intermediary files are in ${tempdir}" >&2
	else
		rm -rf "${tempdir}"
	fi
}

main() {
	global_start=`date +%s`
	print_header
	parse_args $@
	check_requirements	
	init

	invoke_subfinder
	invoke_amass

	merge_wordlist
	prepare_domains_list
	massdns_resolve

	if [[ "${skip_wildcard_check}" -eq 0 ]]; then
		cleanup_wildcards
	fi
	log_success "Found $(domain_count) valid domains!"

	write_output_files
	global_end=`date +%s`
	global_runtime=$((global_end-global_start))
	global_runtimex=$(printf '%dm%ds\n' $(($global_runtime%3600/60)) $(($global_runtime%60)))
	log_success "Found $(domain_count) valid domains in ${global_runtimex}"
	cleanup
}

main $@