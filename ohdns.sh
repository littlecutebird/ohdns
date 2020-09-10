#!/bin/bash

program_name="ohdns"
program_version="v1.0"
program_description="Very fast & accurate dns resolving and bruteforcing."

CURRENT_DIR=$(pwd)
AMASS_BIN="${CURRENT_DIR}/amass/amass"
SUBFINDER_BIN="${CURRENT_DIR}/subfinder/subfinder"
MASSDNS_BIN="${CURRENT_DIR}/massdns/massdns"
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
	echo "ohdns v1.0"
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
	echo "		-d, --domain	Target to scan"
	echo "		-wl, --wordlist	wordlist to do bruteforce"
	echo "		-ac, --amass-config	 Amass config file"
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
	echo "$(cat "${domains_work}" | wc -l)" 2>/dev/null
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
	wildcards_file=''
	wildcard_answers_file=''

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

	if [[ -z "${domains_file}" ]]; then
		usage
		echo "Error: output file is required!"
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
	tempfile_work="${tempdir}/tempfile.txt"

	wildcards_work="${tempdir}/wildcards.txt"
	wildcard_answers_work="${tempdir}/wildcard_answers.txt"
	wildcard_resolving_roots_work="${tempdir}/wildcard_resolving_roots.txt"
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

	log_success "$(domain_count) domains to resolve with massdns"
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
	"${SUBFINDER_BIN}" -d ${domain} -o "${tempdir}/subfinder_output.txt" > /dev/null 2>&1
	end=`date +%s`
	runtime=$((end-start))
	log_success "[SubFinder] Finished | Duration: ${runtime}s"
}

invoke_amass() {
	log_message "[Amass] Running ..."
	start=`date +%s`
	if [[ ! -z "${amass_config}" ]]; then
		"${AMASS_BIN}" enum --passive -nolocaldb -norecursive -noalts -d ${domain} -o "${tempdir}/amass_output.txt" -config ${amass_config} > /dev/null 2>&1
	else
		"${AMASS_BIN}" enum --passive -nolocaldb -norecursive -noalts -d ${domain} -o "${tempdir}/amass_output.txt" > /dev/null 2>&1
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
	massdns_trusted "${domains_work}" "${tmp_massdns_domain_work1}" "${tmp_massdns_work1}"
	log_message "[MassDNS] Running the 2nd time ..."
	massdns_trusted "${domains_work}" "${tmp_massdns_domain_work2}" "${tmp_massdns_work2}"

	log_message "[MassDNS] Merging output from 2 times."
	cat "${tmp_massdns_domain_work1}" "${tmp_massdns_domain_work2}" | sort -u > "${domains_work}"
	log_success "[MassDNS] $(domain_count) domains returned a DNS answer"
}

filter_wildcards_from_answers() {
	domains_grep_file="${tempdir}/wildcard_domains_grep"
	answers_grep_file="${tempdir}/wildcard_answers_grep"
	badrecords_file="${tempdir}/wildcard_badrecords"

	# Create a grep file to match only the entries ending with a wildcard subdomains
	sed -E 's/^\*\.(.*)$/.\1. /' "${wildcards_work}" > "${domains_grep_file}"

	# Create a grep file to match only wildcard answers
	sed -E 's/^(.*)$/ \1/' "${wildcard_answers_work}" > "${answers_grep_file}"

	# Create a list of all the bad records
	grep -Ff "${domains_grep_file}" "${massdns_work}" | grep -Ff "${answers_grep_file}" | sort -u > "${badrecords_file}"

	# Remove bad records from massdns results file
	sort -u "${massdns_work}" > "${tempfile_work}"
	comm -2 -3 "${tempfile_work}" "${badrecords_file}" > "${massdns_work}"

	# Add back known wildcard root subdomains that may have been filtered out
	cat "${massdns_work}" "${wildcard_resolving_roots_work}" | sort -u > ${tempfile_work}
	cp "${tempfile_work}" "${massdns_work}"

	# Extract valid domains
	cat "${massdns_work}" | awk -F '. ' '{ print $1 }' | sort -u > "${domains_work}"
}

cleanup_wildcards() {
	log_message "Detecting wildcard root subdomains..."

	$(dirname $0)/wildcarder --load-massdns-cache "${massdns_work}" --write-domains "${wildcards_work}" --write-answers "${wildcard_answers_work}" "${domains_work}" > /dev/null

	if [[ ! $? -eq 0 ]]; then
		log_error "An error happened running wildcarder. Exiting..."
		cleanup
		exit 1
	fi

	log_success "$(wildcard_count) wildcard root subdomains found"
	if [[ ! "$(wildcard_count)" -eq 0 ]]; then
		cat "${wildcards_work}" >&2

		log_message "Resolving wildcards with trusted resolvers..."
		sed -i 's/^\*\.//' "${wildcards_work}"
		massdns_trusted "${wildcards_work}" "${tempfile_work}" "${wildcard_resolving_roots_work}"
		log_success "Found $(cat "${wildcard_resolving_roots_work}" | wc -l) valid DNS answers for wildcards"

		log_message "Cleaning wildcards from results..."
		filter_wildcards_from_answers
		log_success "$(domain_count) domains remaining"
	fi
}

write_output_files() {
	log_message "Saving output to ${domains_file}"
	echo "" >&2

	if [[ -n "${domains_file}" ]]; then
		cp "${domains_work}" "${domains_file}"
	else
		cat ${domains_work}
	fi

	if [[ -n "${massdns_file}" ]]; then
		cp "${massdns_work}" "${massdns_file}"
	fi

	if [[ -n "${wildcards_file}" ]]; then
		cp "${wildcards_work}" "${wildcards_file}"
		sed -Ei 's/(.*)/*.\1/' "${wildcards_file}"
	fi

	if [[ -n "${wildcard_answers_file}" ]]; then
		cp "${wildcard_answers_work}" "${wildcard_answers_file}"
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

	if [[ "${skip_wildcard_check}" -eq 0 ]] && [[ ! "$(wildcard_count)" -eq 0 ]]; then
		log_message "Removing straggling wildcard results..."
		filter_wildcards_from_answers
	fi

	log_success "Found $(domain_count) valid domains!"

	write_output_files
	#cleanup
	global_end=`date +%s`
	global_runtime=$((global_end-global_start))
	global_runtimex=$(printf '%dm%ds\n' $(($global_runtime%3600/60)) $(($global_runtime%60)))
	log_success "Found $(domain_count) valid domains in ${global_runtimex}"
}

main $@