#!/bin/bash

cat web/native_push_sw_part.js web/native_push_sw_common.js > web/native_push_sw.js
cat web/native_push_sw_non_localize_part.js web/native_push_sw_common.js > web/native_push_sw_non_localize.js

uglifyjs web/native_push.js --compress -m toplevel=true -m "reserved=[native_push_initialNotification, native_push_initializeRemoteNotification, native_push_registerForRemoteNotification]" -o web/native_push.min.js
uglifyjs web/native_push_sw.js --compress -m toplevel=true -o web/native_push_sw.min.js
uglifyjs web/native_push_sw_non_localize.js --compress -m toplevel=true -o web/native_push_sw_non_localize.min.js
