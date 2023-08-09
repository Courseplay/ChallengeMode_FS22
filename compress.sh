zip FS22_ChallengeMode.zip modDesc.xml ChallengeModConfig.xml Icon_ChallengeMode.dds events/* gui/* gui/dialogs/* scripts/* translations/*
mv FS22_ChallengeMode.zip ..


#$compress = @{
#	Path = "modDesc.xml", ".\gui\", ".\events\", ".\scripts\", ".\translations\", "ChallengeModConfig.xml", "Icon_ChallengeMode.dds"
#	DestinationPath = "FS22_ChallengeMode.zip"
#}
#powershell Compress-Archive -Confirm @compress
#mv FS22_ChallengeMode.zip ..


#powershell Compress-Archive modDesc.xml -Update FS22_ChallengeMode.zip
#powershell Compress-Archive -Path Icon_ChallengeMode.dds -Update -DestinationPath FS22_ChallengeMode.zip
#powershell Compress-Archive -Path ChallengeModConfig.xml -Update -DestinationPath FS22_ChallengeMode.zip
#powershell Compress-Archive -Path $(powershell Get-ChildItem -Path events) -Update -DestinationPath FS22_ChallengeMode.zip
#powershell Get-ChildItem -Path gui |
#powershell Compress-Archive -Path gui/* -Update -DestinationPath FS22_ChallengeMode.zip
#powershell Get-ChildItem -Path scripts | powershell Compress-Archive -Update -DestinationPath FS22_ChallengeMode.zip
#powershell Get-ChildItem -Path translations | powershell Compress-Archive -Update -DestinationPath FS22_ChallengeMode.zip
#mv FS22_ChallengeMode.zip ..
