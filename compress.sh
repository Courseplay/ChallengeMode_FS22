# tar.exe -acf FS22_ChallengeMode.zip modDesc.xml ChallengeModConfig.xml Icon_ChallengeMode.dds events/ gui/ scripts/ translations/
#mv FS22_ChallengeMode.zip ..


#$compress = @{
#	Path = "modDesc.xml", ".\gui\", ".\events\", ".\scripts\", ".\translations\", "ChallengeModConfig.xml", "Icon_ChallengeMode.dds"
#	DestinationPath = "FS22_ChallengeMode.zip"
#}
#powershell Compress-Archive -Confirm @compress
#mv FS22_ChallengeMode.zip ..


powershell Compress-Archive modDesc.xml FS22_ChallengeMode.zip
powershell Compress-Archive -Path Icon_ChallengeMode.dds -Update -DestinationPath FS22_ChallengeMode.zip
powershell Compress-Archive -Path ChallengeModConfig.xml -Update -DestinationPath FS22_ChallengeMode.zip
powershell Compress-Archive -Path .\events\ -Update -DestinationPath FS22_ChallengeMode.zip
powershell Compress-Archive -Path .\gui\ -Update -DestinationPath FS22_ChallengeMode.zip
powershell Compress-Archive -Path .\scripts\ -Update -DestinationPath FS22_ChallengeMode.zip
powershell Compress-Archive -Path .\translations\ -Update -DestinationPath FS22_ChallengeMode.zip
mv FS22_ChallengeMode.zip ..
