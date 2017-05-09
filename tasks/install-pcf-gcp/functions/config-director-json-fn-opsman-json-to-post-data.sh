#!/bin/bash
function fn_json_to_post_data {

   return_var=""

   if [[ $2 == "var" ]]; then
     fn_metadata_keys_cmd="echo \$${1}_json | jq 'keys' | jq .[]"
     fn_metadata_cmd="echo \$${1}_json"
   elif [[ $2 == "file" ]]; then
     fn_metadata_keys_cmd="cat ${json_file_path}/${3}.json | jq .[].${1} | jq 'keys' | jq .[]"
     fn_metadata_cmd="cat ${json_file_path}/${3}.json | jq .[].${1}"
   else
     fn_err "$2 is not a matching json source type!!!"
   fi

   if [[ $(eval $fn_metadata_keys_cmd | grep '"pipeline_extension"' | wc -l) -eq 0 ]]; then

         for key in $(eval $fn_metadata_keys_cmd); do
           if [[ $(echo $key | tr -d '"') != "pipeline_extension" ]]; then
             fn_metadata_key_value=$(eval $fn_metadata_cmd | jq .${key})
             key=$(echo $key | tr -d '"')
             fn_metadata_key_value=$(echo $fn_metadata_key_value | sed 's/^"//' | sed 's/"$//')
             return_var="${return_var}&$key=$fn_metadata_key_value"
          else
             echo ""
          fi
         done

   else
          ext_json_data=$(eval $fn_metadata_cmd | jq .)
          ext_cmd="$(eval $fn_metadata_cmd |  jq .pipeline_extension | tr -d '"') \${ext_json_data}"
          return_var=$(eval ${ext_cmd})
   fi

   echo ${return_var}
}
