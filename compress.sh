#!/bin/bash

# Maybe you have to enter "Set-ExecutionPolicy Unrestricted" in Powershell (started with admin rights), because Win10 does not allow the use of non Win10 Powershell scripts without it. :'(
# I used Compress-Archive with a temporary folder because Compress-Archive ignores the specified folder

# Files/Directories to zip
declare -a fd_toZip=(
	"modDesc.xml"
	"ChallengeModConfig.xml"
	"Icon_ChallengeMode.dds"
	"events/"
	"gui/"
	"scripts/"
	"translations/"
)

declare zip_name="FS22_ChallengeMode.zip"

# delete old temp folder + create new one
[[ -e "temp-zip-folder/" ]] && rm -rf "temp-zip-folder/"
mkdir -p "temp-zip-folder/"

# copy files/directorys in temp zip folder
for fd in "${fd_toZip[@]}"
do
	if test -f "$fd"; then	# file
		cp $fd temp-zip-folder/
	elif [ -d "$fd" ]; then	# directory
		cp -r $fd temp-zip-folder/$fd
	fi
done


# delete old zip folder if exists
[[ -e "$zip_name" ]] && rm -f "$zip_name"
# zip temp folder
powershell "Compress-Archive -Path temp-zip-folder/* -DestinationPath $zip_name"

# delete temp zip folder
[[ -e "temp-zip-folder/" ]] && rm -rf "temp-zip-folder/"

# confirm execution
echo "zip is done"
mv "$zip_name" ..
#exec $SHELL		# remove this if you want the console to close on finish