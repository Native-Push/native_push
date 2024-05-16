cat - | jq "{projectId: .project_info.project_id, applicationId: .client.[] | select(.client_info.android_client_info.package_name==\"$1\") | .client_info.mobilesdk_app_id}";
