#!/usr/bin/env bash

plist_info_file_path=""$1"/Info.plist"
plist_info_file_path_backup=${plist_info_file_path}"_backup"

podfile_path="Podfile"
podfile_path_backup=${podfile_path}"_backup"

modifyInfoPlist ()
{
    /usr/libexec/PlistBuddy -c "Set $1 $2" ${plist_info_file_path}
}
#################   Package info - Start #################
# XF inhouse
bundleid_inhouse="com.UPush.LKG"
development_team_inhouse="WP3J3N3HMS"
code_sign_identity_inhouse="iPhone Distribution: Linkage Software CO.,LTD."
provisioning_profile_inhouse="UPush"

#################   Package info - End  #################

# restore from backup if necessary
if [ -f ${podfile_path_backup} ]; then
    mv ${podfile_path_backup} ${podfile_path}
fi

if [ -f ${plist_info_file_path_backup} ]; then
    mv ${plist_info_file_path_backup} ${plist_info_file_path}
fi

bundleid=${bundleid_inhouse}
develop_team=${development_team_inhouse}
code_sign_identity=${code_sign_identity_inhouse}
provisioning_profile=${provisioning_profile_inhouse}
app_group=${app_group_inhouse}

scheme=$1

buildDay=$(date +%Y%m%d)
buildTime=$(date +%m_%d_%H%M)
buildPath="./build"
package=$1

set -e
pushd "$(dirname "$0")"

pod install --repo-update

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${bundleid}" "${package}/Info.plist"

./xcbuild.sh clean -workspace ${package}.xcworkspace -scheme ${scheme}
./xcbuild.sh archive -workspace ${package}.xcworkspace -scheme ${scheme} -archivePath "${buildPath}/${package}_${buildTime}.xcarchive" DEVELOPMENT_TEAM=${develop_team} CODE_SIGN_IDENTITY="${code_sign_identity}" APP_PROFILE=${provisioning_profile}

/usr/libexec/PlistBuddy -c 'Set :method "enterprise"' exportPlist.plist
./xcbuild.sh -exportArchive -archivePath "${buildPath}/${package}_${buildTime}.xcarchive" -exportPath "${buildPath}/${package}_${buildTime}" -exportOptionsPlist exportPlist.plist
#./xcbuild.sh -exportArchive -archivePath "${buildPath}/${package}_${buildTime}.xcarchive"

mv ${buildPath}/${package}_${buildTime}/${package}.ipa ${buildPath}/${package}_${buildTime}.ipa && rm -rf ${buildPath}/${package}_${buildTime}

cp -R ${buildPath}/${package}_${buildTime}.xcarchive/dSYMs/${package}.app.dSYM ${buildPath}/${package}_${buildTime}.dSYM

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier \$(PRODUCT_BUNDLE_IDENTIFIER)" "${package}/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :method "app-store"' exportPlist.plist

# clean up
if [ -f ${podfile_path_backup} ]; then
    mv ${podfile_path_backup} ${podfile_path}
fi

if [ -f ${plist_info_file_path_backup} ]; then
    mv ${plist_info_file_path_backup} ${plist_info_file_path}
fi
