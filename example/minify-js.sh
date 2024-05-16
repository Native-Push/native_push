cat web/native_push_sw_part.js web/native_push_sw_common.js > web/native_push_sw.js
cat web/native_push_sw_non_localize_part.js web/native_push_sw_common.js > web/native_push_sw_non_localize.js

uglifyjs web/native_push.js --compress --mangle -o web/native_push.min.js
uglifyjs web/native_push_sw.js --compress --mangle -o web/native_push_sw.min.js
uglifyjs web/native_push_sw_non_localize.js --compress --mangle -o web/native_push_sw_non_localize.min.js
