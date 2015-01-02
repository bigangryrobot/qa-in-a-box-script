#!/bin/bash
# Clarks QA in a box
 
#conf
export URLFILE="testurllist"
export IPFILE="testiplist"
VISITED_URLS_FILE="/tmp/crawler_visited_urls"
MATCHES_FILE="/tmp/crawler_matches"
EXPR_URL_MATCH="http://[^'\"]\+\.html"
EXPRESSION="[A-Za-z0-9._%\\+-]\\+@[A-Za-z0-9.-]\\+\\.[A-Za-z]\\{2,6\\}"
MAXRECURSIONCOUNT=10
WGET_TIMEOUT=10
WGET_RETRIES=0
START_TIME=`date +%s`
GAWK="/usr/bin/gawk"
USE_URL_LIST=0
export COUNT_OF_ERRORS=0
export countofruns=0
export COUNT_OF_CURLS=1
SAFE_STATUSCODES=( 200 201 202 203 204 205 206 207 208 226 401 301 404 )
export STATUS_UP=`echo -e "\E[32mRUNNING\E[0m"`
export STATUS_DOWN=`echo -e "\E[31mDOWN\E[0m"`
export SCRIPT_LOG=autoUrlChecker/`date +"%Y%m%d"`.autoUrlCheckerReadable.log
export CSVSCRIPT_LOG=autoUrlChecker/`date +"%Y%m%d"`.autoUrlCheckerCSV.log
export UNRECOGNIZEDWORDS_LOG=autoUrlChecker/`date +"%Y%m%d"`.autoUrlCheckerWords.log
export yasnierrors=autoUrlChecker/`date +"%Y%m%d"`.autoUrlCheckeryasnierrors.log
export USER_AGENT_STRING="ClarksURLTester"
 
#user vars to override defaults if needed
while getopts e:t:s:h OPTION; do
case "$OPTION" in
e)
        EXPRESSION=$OPTARG
;;
t)
        RUNTIME=$OPTARG
;;
s)
        SUMMARY=1
;;
h)
        HEADER_URL=$4
;;
*)
        echo "nothing"
;;
esac
done
 
# Figure out a URL from the user. If they didn't specify any, $URL will be blank
while shift; do
        if [[ "$1" == *://* ]]; then
                URL=$1
                break
        fi
done
 
# Sanity check on the user arguments
if [ "$URL" == "" ]; then
                                echo "Error URL required"
                                echo ""
        echo "Syntax: $0 [-s http|http://URL] [-h header][-e search expression] [-t max runtime] "
        echo "Eg, target a site directly: $0 -e panda -t 10 -s https://panda.com"
        echo "Eg, target a server directly: $0 -e panda -t 10 -s https://10.10.1.1 -h www.myloadbalancedsite.com"
        exit 1
fi
 
#getpagestatistics --- still working on this one
GET_PAGE_STATISTICS() {
#find unrecognised words
#UNRECOGNISED_WORDS=`lynx -dump | aspell list | sort -u`
#if [ "$UNRECOGNISED_WORDS=" != "" ] ; then
#                UNRECOGNISED_WORDS_FOUND="X"
#else
#                UNRECOGNISED_WORDS_FOUND=""
#fi
#compare to qa if present
# need to add sed of current url and test to find comperable qa site
GET_URL_STATUS $URL
#search for trigger text
# add function to find specific words or links on a page and send to file
}
 
#urlstatus
GET_URL_STATUS() {
                FULL_STATUS_CODE=""
                export TIME=`date +"%Y%m%d%S"`
                if [[ "$HEADER_URL" == *www* ]]; then
                                RESULT=`curl --HEADER "$HEADER_URL" -A "$USER_AGENT_STRING" -I -L -k --output /dev/null --silent --write-out '%{http_code}:%{time_connect}:%{time_starttransfer}:%{time_total}\n' $URL`
                else
                                RESULT=`curl -A "$USER_AGENT_STRING" -I -L -k --output /dev/null --silent --write-out '%{http_code}:%{time_connect}:%{time_starttransfer}:%{time_total}\n' $URL`
                fi
                STATUS_CODE="$(echo $RESULT | cut -d: -f1)"
    TIME_TO_CONNECT="$(echo $RESULT | cut -d: -f2)"
    TIME_TO_FIRST_BYTE="$(echo $RESULT | cut -d: -f3)"
   TOTAL_TIME="$(echo $RESULT | cut -d: -f4)"
    #SHORTENED_URL="$(echo ${URL})"
                #PAGE="$(echo $URL | awk -F/ '{print $4}')"
                #URI="$(echo $URL | awk -F/ '{print $5}')"
                case $STATUS_CODE in
                                100) FULL_STATUS_CODE="$STATUS_CODE Continue             " ;;
                                101) FULL_STATUS_CODE="$STATUS_CODE Switching Protocol   " ;;
                                102) FULL_STATUS_CODE="$STATUS_CODE Processing (WebDAV) (RFC 2518) " ;;
                                103) FULL_STATUS_CODE="$STATUS_CODE Checkpoint           " ;;
                                122) FULL_STATUS_CODE="$STATUS_CODE Request-URI too long " ;;
                                200) FULL_STATUS_CODE="$STATUS_CODE OK                   " ;;
                                201) FULL_STATUS_CODE="$STATUS_CODE Created              " ;;
                                202) FULL_STATUS_CODE="$STATUS_CODE Accepted             " ;;
                                203) FULL_STATUS_CODE="$STATUS_CODE Non-Authoritative Information" ;;
                                204) FULL_STATUS_CODE="$STATUS_CODE No Content           " ;;
                                205) FULL_STATUS_CODE="$STATUS_CODE Reset Content        " ;;
                                206) FULL_STATUS_CODE="$STATUS_CODE Partial Content      " ;;
                                207) FULL_STATUS_CODE="$STATUS_CODE Multi-Status (WebDAV) (RFC 4918) " ;;
                                208) FULL_STATUS_CODE="$STATUS_CODE Already Reported (WebDAV) (RFC 5842) " ;;
                                226) FULL_STATUS_CODE="$STATUS_CODE IM Used (RFC 3229)   " ;;
                                300) FULL_STATUS_CODE="$STATUS_CODE Multiple Choices     " ;;
                                301) FULL_STATUS_CODE="$STATUS_CODE Moved Permanently    " ;;
                                302) FULL_STATUS_CODE="$STATUS_CODE Found                " ;;
                                303) FULL_STATUS_CODE="$STATUS_CODE See Other            " ;;
                                304) FULL_STATUS_CODE="$STATUS_CODE Not Modified         " ;;
                                305) FULL_STATUS_CODE="$STATUS_CODE Use Proxy            " ;;
                                306) FULL_STATUS_CODE="$STATUS_CODE Switch Proxy         " ;;
                                307) FULL_STATUS_CODE="$STATUS_CODE Temporary Redirect (since HTTP/1.1)" ;;
                                308) FULL_STATUS_CODE="$STATUS_CODE Resume Incomplete    " ;;
                                400) FULL_STATUS_CODE="$STATUS_CODE Bad Request          " ;;
                                401) FULL_STATUS_CODE="$STATUS_CODE Unauthorized         " ;;
                                402) FULL_STATUS_CODE="$STATUS_CODE Payment Required     " ;;
                                403) FULL_STATUS_CODE="$STATUS_CODE Forbidden            " ;;
                                404) FULL_STATUS_CODE="$STATUS_CODE Page Not Found       " ;;
                                405) FULL_STATUS_CODE="$STATUS_CODE Method Not Allowed   " ;;
                                406) FULL_STATUS_CODE="$STATUS_CODE Not Acceptable       " ;;
                                407) FULL_STATUS_CODE="$STATUS_CODE Proxy Authentication Required" ;;
                                408) FULL_STATUS_CODE="$STATUS_CODE Request Timeout      " ;;
                                409) FULL_STATUS_CODE="$STATUS_CODE Conflict             " ;;
                                410) FULL_STATUS_CODE="$STATUS_CODE Gone                 " ;;
                                411) FULL_STATUS_CODE="$STATUS_CODE Length Required      " ;;
                                412) FULL_STATUS_CODE="$STATUS_CODE Precondition Failed  " ;;
                                413) FULL_STATUS_CODE="$STATUS_CODE Request Entity Too Large" ;;
                                414) FULL_STATUS_CODE="$STATUS_CODE Request-URI Too Long " ;;
                                415) FULL_STATUS_CODE="$STATUS_CODE Unsupported MediaType" ;;
                                416) FULL_STATUS_CODE="$STATUS_CODE Requested Range Not Satisfiable" ;;
                                417) FULL_STATUS_CODE="$STATUS_CODE Expectation Failed   " ;;
                                500) FULL_STATUS_CODE="$STATUS_CODE Internal Server Error" ;;
                                501) FULL_STATUS_CODE="$STATUS_CODE Not Implemented      " ;;
                                502) FULL_STATUS_CODE="$STATUS_CODE Bad Gateway          " ;;
                                503) FULL_STATUS_CODE="$STATUS_CODE Service Unavailable  " ;;
                                504) FULL_STATUS_CODE="$STATUS_CODE Gateway Timeout      " ;;
                                505) FULL_STATUS_CODE="$STATUS_CODE HTTP Version Not Supported" ;;
                esac
                REPORT_URL_STATUS $STATUS_CODE
}
 
#url status
REPORT_URL_STATUS() {
                flag=0
                for status in ${SAFE_STATUSCODES[@]}
                do
                                #echo "got Value of STATUS CODE= $1";
                                #echo "Reading Safe Code= $status";
                                                if [ $1 -eq $status ] ; then
                                                                echo "$TIME,1,$TIME_TO_CONNECT,$TIME_TO_FIRST_BYTE,$TOTAL_TIME,$FULL_STATUS_CODE,$COUNT_OF_ERRORS,$COUNT_OF_CURLS,$URL" >> $CSVSCRIPT_LOG
                                                                echo "$TIME   !$STATUS_UP! $TIME_TO_CONNECT! $TIME_TO_FIRST_BYTE! $TOTAL_TIME! $FULL_STATUS_CODE! `printf "% 3d" $COUNT_OF_ERRORS`!   `printf "% 3d" $COUNT_OF_CURLS`!   `printf "% 3d" $(($COUNT_OF_ERRORS*100/$COUNT_OF_CURLS))`%!    $URL" | column -t -s! ;
                                                                flag=1
                                                                break;
                                                fi
                done
 
                if [ $flag -ne 1 ] ; then
                                                if [ $OUTPUT_TYPE -eq "CSV" ] ; then
                                                                echo "$TIME,1,$TIME_TO_CONNECT,$TIME_TO_FIRST_BYTE,$TOTAL_TIME,$FULL_STATUS_CODE,$COUNT_OF_ERRORS,$COUNT_OF_CURLS,$URL" >> $CSVSCRIPT_LOG
                                                                echo "$TIME   !$STATUS_UP! $TIME_TO_CONNECT! $TIME_TO_FIRST_BYTE! $TOTAL_TIME! $FULL_STATUS_CODE! `printf "% 3d" $COUNT_OF_ERRORS`!   `printf "% 3d" $COUNT_OF_CURLS`!   `printf "% 3d" $(($COUNT_OF_ERRORS*100/$COUNT_OF_CURLS))`%!    $URL" | column -t -s! ;
                                                fi
                   ((COUNT_OF_ERRORS ++))
                                break;
                fi
                ((COUNT_OF_CURLS ++))
}
 
SCAN_FOR_URLS() {
if [ "$NEXT_URL" != "" ] ; then
                URL=$NEXT_URL
fi
 
#recursion
START_TIME=`date +%s`
URL_BASE=`echo $URL | awk -F/ '{print $3}'`
 
if [[ "$CRAWLER_RECURSION" == "" ]]; then
        # Remove stale data files from previous runs (if any)
        rm -f $MATCHES_FILE
        export CRAWLER_RECURSION=1
 
        # Create files so there won't be errors reading them before they're formed.
        touch $VISITED_URLS_FILE $MATCHES_FILE
else
        let CRAWLER_RECURSION++
fi
 
# Generate list of links on the page and only include links to the origin domain (dont want to call a surveillance van) and remove duplicates
URL_LIST=`lynx -force_secure -dump $URL | grep -v "java" |  awk '/(http|https):\/\// {print $2}' | grep $URL_BASE | awk '!a[$0]++'`
echo $URL >> $VISITED_URLS_FILE
VISITED_URLS_FILE=`echo $VISITED_URLS_FILE| awk '!a[$0]++'`
GET_URL_STATUS
 
for NEXT_URL in $URL_LIST; do
        CURRENT_TIME=`date +%s`
        if ! grep -q $NEXT_URL $VISITED_URLS_FILE; then
                                SCAN_FOR_URLS $NEXT_URL
        fi
        ((RECURSIONCOUNT ++))
done
 
if [[ "$CRAWLER_RECURSION" == "1" ]]; then
        # Clean shit up
        rm $MATCHES_FILE
        rm $VISITED_URLS_FILE
        unset CRAWLER_RECURSION
fi
 
let CRAWLER_RECURSION--
}
 
#main loop
MAIN_LOOP() {
while true
do
SCAN_FOR_URLS
done
}
 
#print initial header
echo "----------- :--------- :----- :----- :----- :------------------------- :----- :----- :------ :------" | column -t -s: ;
echo "TIME       |: STATUS  |: C T |: F B |: T T |: FULL STATUS             |: ERR |: RUN |: ERR %|: URL  |" | column -t -s: ;
echo "----------- :--------- :----- :----- :----- :------------------------- :----- :----- :------ :------" | column -t -s: ;
               
rm -f $VISITED_URLS_FILE
MAIN_LOOP | tee -a $SCRIPT_LOG
