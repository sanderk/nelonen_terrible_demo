#!/bin/bash
function putS3
{
    path=$1
    filename=$2
    aws_path="/$BACKUP_PREFIX/$path/$(date +%Y-%m-%d)/"
    bucket='snm-nl-backup'
    date=$(date +"%a, %d %b %Y %T %z")
    acl="x-amz-acl:private"
    content_type='application/x-compressed-tar'
    string="PUT\n\n$content_type\n$date\n$acl\n/$bucket$aws_path$filename"
    echo "Putting $filename to $aws_path$ ... "
    signature=$(echo -en "${string}" | openssl sha1 -hmac "${AWS_SECRET}" -binary | base64)
    curl -X PUT -T "$filename" \
    -H "Host: $bucket.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${AWS_KEY}:$signature" \
    "https://$bucket.s3.amazonaws.com$aws_path$filename" &> /dev/null

    transfer_result=$?
}

STARTTIME="$(date +%s%3N)"
echo -e "\n\n\n ---- BACKUP STARTED AT $(date -R) -----\n\n"

BACKUP_CONFIG="/etc/sysconfig/aws_backup"

if [ ! -f "$BACKUP_CONFIG" ]; then
  echo "$BACKUP_CONFIG could not be found, no config to be retrieved. Exiting."
  exit
fi

. "$BACKUP_CONFIG"

if [ -z "${BACKUP_DIR+x}" ] || [ -z "${AWS_KEY+x}" ] || [ -z "${AWS_SECRET+x}" ]; then
    echo "You'll be needing the BACKUP_DIR, AWS_KEY, and AWS_SECRET. Make sure they're set in $BACKUP_CONFIG".
    exit
fi

echo "Checking $BACKUP_DIR"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "$BACKUP_DIR does not exist - creating"
    mkdir -p $BACKUP_DIR
fi

echo -e "All vars set, backup dir $BACKUP_DIR exists, let the backup commence! \n\n"

counter=0
fails=0

# Quit if you cannot find the backup-dir
cd "$BACKUP_DIR" || exit
while IFS= read -r -d '' filename
do
    echo "Processing $filename .."
    putS3 "$(hostname -s)" "$filename"
    if [ "$transfer_result" -gt 0 ]; then
      echo "Failed putting $filename in to the bucket"
      let fails++
    fi

    let counter++
done<   <(find * -mtime -1 -type f -print0 2>/dev/null)

echo "Put $counter files into the bucket. "
echo "Backup has been copied into Amazon. Logging result into CheckMK log"
ENDTIME="$(date +%s%3N)"
TOTAL_ELAPSED_TIME=$(echo "scale=3; $((ENDTIME-STARTTIME))/1000" | bc)

perfdata="files_processed=$counter|failed=$fails|execution_time=$TOTAL_ELAPSED_TIME"

application_name="AWSBackup"
resultcode=0
if [ $fails -gt 0 ]; then
    resultcode=1
    if [ $fails -eq $counter ]; then
        resultcode=2
    fi
fi
message="Finished processing $counter files in $TOTAL_ELAPSED_TIME seconds"

log_content="<<<local>>>\n$resultcode $application_name $perfdata $message\n"
spool_agent_dir="/var/lib/check_mk_agent/spool"
filename="86400_$application_name.txt"

mkdir -p $spool_agent_dir
# And now put $log_content into $spool_agent/$filename
echo -e "$log_content" > "$spool_agent_dir/$filename"

echo -e "Logged to CheckMK. \n\n ---- BACKUP DONE AT $(date -R) -----"

