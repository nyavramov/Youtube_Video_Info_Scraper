#!/bin/bash

#Initialize variables
index=0
quoteCounter=0
emptyString=""
titlesListCleaned=()
timesList2=()

# Grab the relevant html for every video and discard the rest
grep '</ytd-thumbnail>.*class="style-scope ytd-grid-video-renderer">' index.html > index4.html

# List of authors for each video
users=(`egrep -o '[user|channel]/[A-Za-z0-9]*' index4.html | cut -d "/" -f2`)

# List of views for each video
views1=(`egrep -o '[0-9,]* views' index4.html`)

# Remove each instance of word 'views' from array
views2=(${views1[@]//views/})

# List of durations for each video
timesList=(`egrep -o '[0-9]*[[:blank:]](minutes|seconds),*[[:blank:]][seconds]*' index4.html`)

# List of titles for each video
titlesList=(`egrep -o 'title="[^"]*"' index4.html | cut -d "=" -f2`)

# Sanitized list of video IDs
videoIDList=(`egrep -o 'v=[^"]*"' index4.html | cut -d "=" -f2 | cut -d "\"" -f1`)

for ((i=0; i<${#timesList[@]};i++)); do

    # If empty string is not empty, insert space before item
    if [ "${emptyString}" != "" ]; then

	emptyString+=" ${timesList[$i]}"

    else
	
	emptyString+="${timesList[$i]}"

    fi

    # If item has only 'minutes', lacks seconds so prepend them
    if [ "${timesList[i]}" == "minutes" ]; then

	emptyString+=", 0 seconds"

	timesList2+=("$emptyString")

	emptyString=""
 	
    elif [ "${timesList[i]}" == "seconds" ] && [ "${timesList[i-1]}" -lt "60" ]; then

	timesList2+=("${emptyString}")
	
	emptyString=""

    # If youtube inexplicably lists duration greater than 60 second w/o minutes, convert
    # the duration to normal 'X minutes, Y seconds' form
    elif [ "${timesList[i]}" == "seconds" ] && [ "${timesList[i-1]}" -ge "60" ]; then
       
	number=${timesList[i-1]}
	
	minutes=$((number/60))
	
	seconds=$((number%60))

	emptyString="${minutes} minutes, ${seconds} seconds"

	timesList2+=("${emptyString}")

	emptyString=""

    fi
    
done

for ((j = 0; j < ${#titlesList[@]}; j++)); do

    # If not start of title, insert a space
    if [ "${emptyString}" != "" ]; then

	emptyString+=" ${titlesList[$j]}"

    # If at start, don't insert a space
    else
	
	emptyString+="${titlesList[$j]}"

    fi

    # If reached 2nd double quote, add content of emptyString to list
    if [[ "${titlesList[j]}" == *\"* ]] && [ "$quoteCounter" -eq "2" ]; then

	titlesListCleaned+=("$emptyString")

	emptyString=""

	quoteCounter=0
   	
    elif [ "$quoteCounter" -ne "2" ]; then
	
	((quoteCounter++))

    fi
    
done

echo
echo "AUTHOR                   VIEWS      DURATION                  Video ID       TITLE"
echo "----------               --------   -----------------------   -----------    --------------------------"

for viewCount in ${views2[@]}; do

    shortTitle="`echo ${titlesListCleaned[$index]} | cut -d " " -f 1,2,3,4,5,6,7,8`"

    printf "%-25s%-11s%-3s%-9s%-3s %-9s %-13s %-s %-s %-s %-s %-s %-s %-s %-s %-s\n" ${users[$index]} ${viewCount//,/} ${timesList2[$index]} ${videoIDList[$index]} ${shortTitle}

    ((index++))

done

echo
