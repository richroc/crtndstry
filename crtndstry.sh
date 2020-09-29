#!/bin/bash
# This was created during a live stream on 11/16/2019
# twitch.tv/nahamsec
# Thank you to nukedx and dmfroberson for helping debug/improve

certdata(){
	#This should cover the entire domain:
	crtsh1=$(curl -s  "https://crt.sh/?q=$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a rawdata/crtsh1.txt || '')
        echo "$crtsh1"
        #give it patterns to look for within crt.sh for example %api%.site.com - This may be redundant at this point but we'll leave it.
        declare -a arr=("api" "corp" "dev" "uat" "test" "stage" "sandbox" "prod" "internal")
        for i in "${arr[@]}"; do
                #get a list of domains based on our patterns in the array
                sub="${i}.$1"
                url="https://crt.sh/?q=${sub}&output=json"
                crtsh=`curl -s "${url}"`
                crtsh=`echo ${crtsh} | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a rawdata/crtsh.txt || ''`
        done
                #get a list of domains from certspotter
                #certspotter=$(curl -s "https://api.certspotter.com/v1/issuances?domain=$1&expand=dns_names&expand=issuer&include_subdomains=true" | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep -w $1\$ | tee rawdata/certspotter.txt)
                certspotter=$(curl -s "https://api.certspotter.com/v1/issuances?domain=$1&expand=dns_names&expand=issuer&include_subdomains=true" | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | tee rawdata/certspotter.txt)
                echo "$crtsh1"
                echo "$crtsh"
                echo "$certspotter"
}



rootdomains() { #this creates a list of all unique root sub domains
        clear
        echo "working on data"
        cat rawdata/crtsh1.txt | rev | cut -d "." -f 1,2,3 | sort -u | rev | tee ./$1-temp.txt
        cat rawdata/crtsh.txt | rev | cut -d "." -f 1,2,3 | sort -u | rev | tee -a ./$1-temp.txt
        cat rawdata/certspotter.txt | rev | cut -d "." -f 1,2,3 | sort -u | rev | tee -a ./$1-temp.txt
        domain=$1
        #jq -r '.data.certificateDetail[].commonName,.data.certificateDetail[].subjectAlternativeNames[]' rawdata/digicert.json | sed 's/"//g' | grep -w "$domain$" | rev | cut -d "."  -f 1,2,3 | sort -u | rev | tee -a ./$1-temp.txt
        cat $1-temp.txt | sort -u | tee ./data/$1-$(date "+%Y.%m.%d-%H.%M").txt; rm $1-temp.txt
        cat rawdata/*.txt >> ./data/$1-Full_Domains.txt
        rm -rf rawdata/*.txt
        echo "Number of domains found: $(cat ./data/$1-$(date "+%Y.%m.%d-%H.%M").txt | wc -l)"
}

certdata $1
rootdomains $1
echo "All Unique root sub domains: $(cat ./data/$1-$(date "+%Y.%m.%d-%H.%M").txt | wc -l)"
echo "All Unique domains: $(cat ./data/$1-Full_Domains.txt | wc -l)"
