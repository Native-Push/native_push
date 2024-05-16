#!/bin/bash

JSON=$(cat google-services.json);
PROJECT_ID=$(echo "$JSON" | jq -r ".project_info.project_id");
CLIENTS=$(echo "$JSON" | jq -c -r ".client.[] | {packageName: .client_info.android_client_info.package_name, appId: .client_info.mobilesdk_app_id}");

for CLIENT in $CLIENTS; do
  if [ "$(echo "$CLIENT" | jq -r ".packageName")" = "$1" ]; then
    echo "$CLIENT" | jq -r "{projectId: \"$PROJECT_ID\", applicationId: .appId}";
    exit 0;
  fi;
done;

echo "App with package name $1 not found.";
exit 1;
