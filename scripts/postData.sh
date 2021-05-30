#!/bin/bash
source $ALLSKY_HOME/config.sh
source $ALLSKY_HOME/scripts/ftp-settings.sh

LATITUDE="`jq -r '.'latitude $CAMERA_SETTINGS`"
LONGITUDE="`jq -r '.'longitude $CAMERA_SETTINGS`"
# TODO(lmr): what timezone do i put here?
TIMEZONE="-0700"
# TODO Needs fixing when civil twilight happens after midnight
cd $ALLSKY_HOME/scripts

streamDaytime=false

if [[ $DAYTIME == "1" ]] ; then
	streamDaytime=true;
fi

echo "Posting Next Twilight Time"
today=`date +%Y-%m-%d`
time="$(sunwait list set civil $LATITUDE $LONGITUDE)"
timeNoZone=${time:0:5}
echo { > data.json
echo \"sunset\": \"$today"T"$timeNoZone":00.000$TIMEZONE"\", >> data.json
echo \"streamDaytime\": \"$streamDaytime\" >> data.json
echo } >> data.json
echo "Uploading data.json"
if [[ $PROTOCOL == "S3" ]] ; then
        $AWS_CLI_DIR/aws s3 cp data.json s3://$S3_BUCKET$IMGDIR --acl $S3_ACL &
elif [[ $PROTOCOL == "local" ]] ; then
	cp data.json $IMGDIR &
else
        lftp "$PROTOCOL"://"$USER":"$PASSWORD"@"$HOST":"$IMGDIR" -e "set net:max-retries 1; set net:timeout 20; put data.json; bye" &
fi
