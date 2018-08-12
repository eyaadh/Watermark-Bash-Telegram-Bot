#!/usr/bin/env bash

tg_config_dir=`pwd`
config=`cat $tg_config_dir/.tgconfig`
users_data_file="${tg_config_dir}/users.json"
users_data_Tfile="${tg_config_dir}/users.new"

token=$(echo $config | jq -r ".config.token")
api_url=$(echo $config | jq -r ".config.api_url")
tele_url="${api_url}${token}"

last_id_file="$tg_config_dir/LAST_ID"
last_id=0

if [ ! -f $last_id_file ];
then
    touch $last_id_file
    echo 0 > $last_id_file    
else
    last_id=$(cat $last_id_file)

fi

function loop_core() {
    while true; do 
        process_reply 
        sleep 1
    done
}

function process_reply() {
	local i update message_id chat_id text

	local updates=$(curl -s "${tele_url}/getUpdates?offset=$last_id")
	local count_update=$(echo $updates | jq -r ".result | length") 
    
	[[ $count_update -eq 0 ]] && echo -n "."

	for ((i=0; i<$count_update; i++)); do
    	update=$(echo $updates | jq -r ".result[$i]")   
    	last_id=$(echo $update | jq -r ".update_id")     
    	message_id=$(echo $update | jq -r ".message.message_id")    
    	chat_id=$(echo $update | jq -r ".message.chat.id") 
    	user_id=$(echo $update | jq -r ".message.from.id") 
		first_name=$(echo $update | jq -r ".message.from.first_name")        

		text=$(echo $update | jq -r ".message.text") 
		first_word=$(echo $text | head -n 1 | awk '{print $1;}')

		local update_with_new_callbckQery=$(echo $update | jq -r ".callback_query | select(.data !=null)")
		local update_with_new_reply=$(echo $update | jq -r ".message.reply_to_message | select(.message_id !=null)")

		modw_inline_keyboard='{"inline_keyboard":[[{"text":"Text","callback_data":"mode_text"},{"text":"Picture","callback_data":"mode_picture"}]]}'
		fsize_inline_keyboard='{"inline_keyboard":[[{"text":"16","callback_data":"f16"},{"text":"20","callback_data":"f20"},{"text":"24","callback_data":"f24"}],[{"text":"28","callback_data":"f20"},{"text":"30","callback_data":"f30"},{"text":"32","callback_data":"f32"}],[{"text":"36","callback_data":"f36"},{"text":"40","callback_data":"f40"},{"text":"46","callback_data":"f46"}],[{"text":"50","callback_data":"f50"},{"text":"56","callback_data":"f56"},{"text":"60","callback_data":"f60"}]]}'
		tcolor_inline_keyboard='{"inline_keyboard":[[{"text":"White","callback_data":"twhite"},{"text":"Silver","callback_data":"tsilver"},{"text":"Gray","callback_data":"tgray"}],[{"text":"Black","callback_data":"tblack"},{"text":"Red","callback_data":"tred"},{"text":"Maroon","callback_data":"tmaroon"}],[{"text":"Yellow","callback_data":"tyellow"},{"text":"Green","callback_data":"tgeen"},{"text":"Blue","callback_data":"tblue"}]]}'
		position_inline_keyboard='{"inline_keyboard":[[{"text":"NorthWest","callback_data":"nw"},{"text":"North","callback_data":"nn"},{"text":"NorthEast","callback_data":"ne"}],[{"text":"West","callback_data":"ww"},{"text":"Center","callback_data":"cc"},{"text":"East","callback_data":"ee"}],[{"text":"SouthWest","callback_data":"sw"},{"text":"South","callback_data":"ss"},{"text":"SouthEast","callback_data":"se"}]]}'
		opacity_inline_keyboard='{"inline_keyboard":[[{"text":"25","callback_data":"o25"},{"text":"50","callback_data":"o50"},{"text":"100","callback_data":"o100"}]]}'
		if [ -n "$update_with_new_callbckQery" ]; then
			cb_q=$(echo $update | jq -r ".callback_query") 
			cb_data=$(echo $cb_q | jq -r ".data")
			cb_q_id=$(echo $cb_q | jq -r ".id")
			cb_q_mid=$(echo $cb_q | jq -r ".message.message_id")
			cb_q_uid=$(echo $cb_q | jq -r ".from.id")
			cb_chat_id=$(echo $cb_q | jq -r ".message.chat.id")
		

			if [ "$cb_data" == "mode_text" ]; then
				if [ "$dat_stat" == "editmode${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .mode=\"text\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="_Text_ Method has been selected for watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
					
				else
					#update mode to text for relavent user	
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .mode=\"text\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					#finally send a message asking to set the font size
					msg="Perfect, _Text_ Method has been selected, now lets decide the *font size.*"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$fsize_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f16" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"16\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _16_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"16\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file			
				
					msg="Ok, Font size set to _16_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi	
			elif [ "$cb_data" == "f20" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"20\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _20_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"20\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _20_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								 --data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f24" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"24\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _24_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"24\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _24_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
									-d chat_id="${cb_chat_id}" \
									-d message_id="${cb_q_mid}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
									-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f28" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"28\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _28_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"28\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _28_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f30" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"30\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _30_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"30\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _30_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f32" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"32\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _32_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"32\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _32_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f36" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"36\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _36_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"36\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _36_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
									--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f40" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"40\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _40_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"40\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _40_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "f46" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"46\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _46_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"46\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _46_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			
			elif [ "$cb_data" == "f50" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"50\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _50_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"50\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _50_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			
			elif [ "$cb_data" == "f56" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"56\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _56_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"56\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _56_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			
			elif [ "$cb_data" == "f60" ]; then
				if [ "$dat_stat" == "editfontonly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"60\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Font size set to _60_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.font_size=\"60\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Ok, Font size set to _60_. Which *color* do you want the watermark to be in?"
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$tcolor_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			
			elif [ "$cb_data" == "twhite" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FFFFFF\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _White_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FFFFFF\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _white_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tsilver" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#C0C0C0\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Silver_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#C0C0C0\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _silver_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tgray" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#808080\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Gray_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#808080\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _gray_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tblack" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#000000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Black_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#000000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _black_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tred" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FF0000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Red_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FF0000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _red_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tmaroon" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#800000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Maroon_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#800000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _maroon_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tyellow" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FFFF00\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Yellow_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#FFFF00\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _yellow_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tgeen" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#008000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Green_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#008000\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _green_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "tblue" ]; then
				if [ "$dat_stat" == "editcoloronly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#0000FF\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Ok, Text color set to _Blue_."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.color=\"#0000FF\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Font color set to _blue_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "nw" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"NorthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _NorthWest_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"NorthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"NorthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _NorthWest_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"NorthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
				
					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
									)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "nn" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"North\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _North_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"North\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"North\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _North_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"North\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "ne" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"NorthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _NorthEast_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"NorthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"NorthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _NorthEast_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"NorthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "ww" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"West\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _West_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"West\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"West\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _West_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"West\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result
				
					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "cc" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"Center\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _Center_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"Center\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"Center\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _Center_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"Center\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "ee" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"East\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _East_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"East\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"East\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _East_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"East\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "sw" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"SouthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _SouthWest_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"SouthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt	
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"SouthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _SouthWest_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"SouthWest\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "ss" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"South\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file


					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _South_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"South\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"South\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _South_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"South\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "se" ]; then
				if [ "$dat_stat" == "edittextpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"SouthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result
					
					msg="Settings updated to place the watermark at _SouthEast_ of the picture."
					result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${cb_chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicopc${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"SouthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *logo* you would like to set as a picture watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				elif [ "$dat_stat" == "editpicpositiononly${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.position=\"SouthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Placement of Picture Logo updated to _SouthEast_."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.position=\"SouthEast\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					result=$(curl -s "${tele_url}/deleteMessage" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
							)
					echo $result

					msg="Ok now as a last step as a reply of this message send me the *text* you would like to enter on watermark."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup='{"force_reply": true}'
							)
					echo $result

					rep_ackid=$(echo $result  | jq -r ".result.message_id" )
					echo $rep_ackid >> ${tg_config_dir}/repmsg.id

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi

			elif [ "$cb_data" == "mode_picture" ]; then
				if [ "$dat_stat" == "editmode${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .mode=\"picture\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="_Picture_ Method has been selected for watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .mode=\"picture\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="Cool, let's set the *opacity* for your logo, 25 will make the logo more transparent and 100 will be less transparent."
					result=$(curl -s "${tele_url}/sendMessage" \
								-d chat_id="${cb_chat_id}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$opacity_inline_keyboard" \
							)
					echo $result
					
					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
				fi
			elif [ "$cb_data" == "o25" ]; then
				if [ "$dat_stat" == "editopacity${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"25\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="Opactiy set to _25_."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"25\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Opacity set to _25_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat="editpicopc${cb_chat_id}"
				fi
			elif [ "$cb_data" == "o50" ]; then
				if [ "$dat_stat" == "editopacity${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"50\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="Opactiy set to _50_."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"50\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Opacity set to _50_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat="editpicopc${cb_chat_id}"
				fi	
			elif [ "$cb_data" == "o100" ]; then
				if [ "$dat_stat" == "editopacity${cb_q_uid}" ]; then
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"100\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					
					msg="Opactiy set to _100_."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat=""
				else
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.opacity=\"100\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file

					msg="Opacity set to _100_. Lets also decidde on where to *place* the watermark."
					result=$(curl -s "${tele_url}/editMessageText" \
								-d chat_id="${cb_chat_id}" \
								-d message_id="${cb_q_mid}" \
								-d text="${msg}" \
								-d parse_mode="markdown" \
								-d reply_markup="$position_inline_keyboard" \
							)
					echo $result

					result=$(curl -s "${tele_url}/answerCallbackQuery" \
								--data-urlencode "callback_query_id=${cb_q_id}" \
							)
					echo $reuslt
					
					dat_stat="editpicopc${cb_chat_id}"
				fi
			fi

		elif [ -n "$update_with_new_reply" ]; then
			
			rp_msg_id=$(echo $update | jq -r ".message.reply_to_message.message_id")
			
			readarray rep_msg_aid < ${tg_config_dir}/repmsg.id
			for ((i=0; i < ${#rep_msg_aid[@]}; i++))
			do
				if [ ${rep_msg_aid[$i]} = $rp_msg_id ]; then
					m_text=$(echo $update | jq -r ".message.text")	
				
					if [ "$dat_stat" == "edittextonly${user_id}" ]; then
						jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.text=\"${m_text}\"  else . end)))" $users_data_file > $users_data_Tfile
						mv $users_data_Tfile $users_data_file
						
						msg="Text has been updated to ${m_text}."
						result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" 
								)
						echo $result
					
						dat_stat=""
					
					else
						jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .text.text=\"${m_text}\"  else . end)))" $users_data_file > $users_data_Tfile
						mv $users_data_Tfile $users_data_file
						

						msg="Perfect that completes all the settings now you can send me photos and I will do the magic for you."
						result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" 
								)
						echo $result
					fi
				fi
			done
			
			readarray reppc_msg_aid < ${tg_config_dir}/reppcmsg.id
			for ((i=0; i < ${#reppc_msg_aid[@]}; i++))
			do
				if [ ${reppc_msg_aid[$i]} = $rp_msg_id ]; then
				
					typeset -i num_imgs=$(echo $update | jq -c ".message.photo[]" | wc -l )
					lg_file_id=$(echo $update | jq -r ".message.photo[$((num_imgs-1))].file_id" )
					req_lgfilepath=$(curl -s "${tele_url}/getFile" -d file_id="$lg_file_id")
					lg_file_path=$(echo $req_lgfilepath | jq -r ".result.file_path")
					
					jq "(.users)|=(map((if .user_id|startswith(\"${cb_q_uid}\") then .picture.file=\"${lg_file_path}\"  else . end)))" $users_data_file > $users_data_Tfile
					mv $users_data_Tfile $users_data_file
					if [ "$dat_stat" == "editpicture${user_id}" ]; then
						msg="A new image has been set for watermark."
						result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" 
								)
						echo $result
						
						dat_stat=""
						
					else
						msg="Perfect that completes all the settings now you can send me photos and I will do the magic for you."
						result=$(curl -s "${tele_url}/sendMessage" \
									-d chat_id="${chat_id}" \
									-d text="${msg}" \
									-d parse_mode="markdown" 
								)
						echo $result
					fi
				fi
			done

		elif [ "$first_word" == "/start" ]; then
			u_data=`cat $users_data_file`
			user_stat=$(echo $u_data | jq  -r ".users[] | select(.user_id==\"${user_id}\")")
			
			if [ "$user_stat" == "" ]; then
				#add new user entery json file
				jq ".users += [{\"user_id\":\"${user_id}\", \"mode\":\"null\", \"text\":{\"font_size\":\"null\", \"color\":\"null\", \"position\":\"null\", \"text\":\"null\"}, \"picture\":{\"file\":\"null\", \"opacity\":\"null\", \"position\":\"null\"}}]" $users_data_file > $users_data_Tfile
				mv $users_data_Tfile $users_data_file

				msg="Hello [@${first_name}](tg://user?id=${user_id}), It's very nice to meet you. I could help you attach watermarks to your photos. %0ASeems like you are a new here, lets do the initial setup. %0A*Firstly would you like to attach a Picture or a Text watermark?* %0A_You could always edit the saved configurations by issuing the command_ /editsettings "
				result=$(curl -s "${tele_url}/sendMessage" \
							-d chat_id="${chat_id}" \
							-d text="${msg}" \
							-d parse_mode="markdown" \
							-d reply_markup="$modw_inline_keyboard"
						)
				echo $result
			else
				msg="Hello [@${first_name}](tg://user?id=${user_id}) 🙋‍♂️  It's very nice to meet you. I could help you attach watermarks to your photos 🎞. %0AKindly review \`help\` for more details by issueing the command /help."
				result=$(curl -s "${tele_url}/sendMessage" \
							-d chat_id="${chat_id}" \
							-d text="${msg}" \
							-d parse_mode="markdown"
					)
				echo $result
			fi

		elif [ "$first_word" == "/editsettings" ]; then
			chk_user $user_id
			
			if [ "$user_stat" == "" ]; then
				#add new user entery json file
				jq ".users += [{\"user_id\":\"${user_id}\", \"mode\":\"null\", \"text\":{\"font_size\":\"null\", \"color\":\"null\", \"position\":\"null\", \"text\":\"null\"}, \"picture\":{\"file\":\"null\", \"opacity\":\"null\", \"position\":\"null\"}}]" $users_data_file > $users_data_Tfile
				mv $users_data_Tfile $users_data_file

				msg="Hello [@${first_name}](tg://user?id=${user_id}), Its vert nice to meet you. I could help you attach watermarks to your photos. %0ASeems like you are a new here, lets do the initial setup. %0A*Firstly would you like to attach a Picture or a Text watermark?* %0A_You could always edit the saved configurations by issuing the command_ /editsettings "
				result=$(curl -s "${tele_url}/sendMessage" \
							-d chat_id="${chat_id}" \
							-d text="${msg}" \
							-d parse_mode="markdown" \
							-d reply_markup="$modw_inline_keyboard"
						)
				echo $result
			else
				msg="Hello [@${first_name}](tg://user?id=${user_id}), your current settings are as follows: %0A*Active Watermark Mode:* ${u_mode} %0A*Wattermark Settings for Text:* %0A*-Font Size:* ${u_fsize} %0A*-Color:* ${u_color} %0A*-Position:* ${u_position} %0A*Wattermark Settings for Picture:* %0A*-Opacity: *${up_opacity} %0A*-Position: *${up_position}"
				result=$(curl -s "${tele_url}/sendMessage" \
							-d chat_id="${chat_id}" \
							-d text="${msg}" \
							-d parse_mode="markdown" \
							-d reply_markup="$modw_inline_keyboard"
						)
				 echo $result

			fi
		elif [ "$first_word" == "/edittextsize" ]; then
		
			chk_user $user_id
			dat_stat="editfontonly${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), Font Size on current settings is ${u_fsize}, Kindly select a *New Font Size from the bellow options:*"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$fsize_inline_keyboard"
					)
			echo $result

		
		elif [ "$first_word" == "/edittextcolor" ]; then
		
			chk_user $user_id
			dat_stat="editcoloronly${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), You have set Color as ${u_color} on the current settings, Kindly select the *New Color from the options bellow:*"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$tcolor_inline_keyboard"
					)
			echo $result
			
		elif [ "$first_word" == "/edittextposition" ]; then
		
			chk_user $user_id
			dat_stat="edittextpositiononly${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), On the current settings it is set to place the watermark at ${u_position}, Kindly select a *New Position from the bellow options:*"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$position_inline_keyboard"
					)
			echo $result
		
		elif [ "$first_word" == "/edittext" ]; then
		
			chk_user $user_id
			dat_stat="edittextonly${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), You have set Text as ${u_text} on the current settings, Kindly set a *New Text* for the watermark *by replying to this message* with a new pharase you want to put in the watermark"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup='{"force_reply": true}'
					)
			echo $result
			
			rep_ackid=$(echo $result  | jq -r ".result.message_id" )                
			echo $rep_ackid >> ${tg_config_dir}/repmsg.id
			
		elif [ "$first_word" == "/editmode" ]; then
		
			chk_user $user_id
			dat_stat="editmode${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), You have set to _${u_mode}_ , Kindly select the *New Mode* from bellow given options:"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$modw_inline_keyboard" \
					)
			echo $result
			
		elif [ "$first_word" == "/editpicture" ]; then
		
			chk_user $user_id
			dat_stat="editpicture${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), As a reply of this message kindly send the *New Image* to set as the watermark."
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup='{"force_reply": true}'
					)
			echo $result

			reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
			echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id
		
		elif [ "$first_word" == "/editopacity" ]; then
		
			chk_user $user_id
			dat_stat="editopacity${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), On the current settings Opacity is set to: _${up_opacity}_. Kindly select a *New Opacity* from the bellow options."
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$opacity_inline_keyboard"
					)
			echo $result

			reppc_ackid=$(echo $result  | jq -r ".result.message_id" )
			echo $reppc_ackid >> ${tg_config_dir}/reppcmsg.id
		
		elif [ "$first_word" == "/editpicposition" ]; then
		
			chk_user $user_id
			dat_stat="editpicpositiononly${user_id}"
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), On the current settings Picture Logo is placed at: _${up_position}_. Kindly select a *New Position* from the bellow options:"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d reply_markup="$position_inline_keyboard"
					)
			echo $result
			
		elif [ "$first_word" == "/viewsettings" ]; then
		
			chk_user $user_id
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), your current settings are as follows: %0A*Active Watermark Mode:* ${u_mode} %0A*Wattermark Settings for Text:* %0A*-Font Size:* ${u_fsize} %0A*-Color:* ${u_color} %0A*-Position:* ${u_position} %0A*Wattermark Settings for Picture:* %0A*-Opacity: *${up_opacity} %0A*-Position: *${up_position} %0A\`If any of the above settings has a value as null that is because it has been not set yet. You can set them by issueing the command /editsettings otherwise by issueing the edit command for the relavent option i.e. for example /editposition %0AFor more details issue /help command.\`"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
					)
			echo $result
			
		elif [ "$first_word" == "/help" ]; then
		
			help_msg=`cat ${tg_config_dir}/help`
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), ${help_msg}"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d disable_web_page_preview=true \
					)
			echo $result
		elif [ "$first_word" == "/getsource" ]; then
		
			help_msg=`cat ${tg_config_dir}/README.md`
			
			msg="Hello [@${first_name}](tg://user?id=${user_id}), %0A${help_msg}"
			result=$(curl -s "${tele_url}/sendMessage" \
						-d chat_id="${chat_id}" \
						-d text="${msg}" \
						-d parse_mode="markdown" \
						-d disable_web_page_preview=true \
					)
			echo $result
		
		else
			typeset -i num_imgs=$(echo $update | jq -c ".message.photo[]" | wc -l )
			file_id=$(echo $update | jq -r ".message.photo[$((num_imgs-1))].file_id" )
			req_filepath=$(curl -s "${tele_url}/getFile" -d file_id="$file_id")
			file_path=$(echo $req_filepath | jq -r ".result.file_path")
			file_name=$(echo $file_path | cut -d "/" -f2)

			if [ "$file_id" != "null" ]; then
				
				chk_user $user_id
				
				if [ "$u_mode" == "picture" ]; then
				
					up_file_name=$(echo $up_file | cut -d "/" -f2)
					wget https://api.telegram.org/file/bot$token/$up_file -P ${tg_config_dir}/
					
					wget https://api.telegram.org/file/bot$token/$file_path -P ${tg_config_dir}/
					
					composite -dissolve ${up_opacity} -gravity ${up_position} ${tg_config_dir}/${up_file_name} ${tg_config_dir}/${file_name} ${tg_config_dir}/${file_name}2
					
					result=$(curl -s "${tele_url}/sendPhoto" \
								-F chat_id="${chat_id}" \
								-F photo=@${tg_config_dir}/${file_name}2
							)
					echo $result
					
					rm -rf ${tg_config_dir}/${up_file_name}
					rm -rf ${tg_config_dir}/${file_name}
					rm -rf ${tg_config_dir}/${file_name}2

				else
					wget https://api.telegram.org/file/bot$token/$file_path -P ${tg_config_dir}/
							
					convert ${tg_config_dir}/${file_name} -gravity "${u_position}" -pointsize "${u_fsize}" -fill "${u_color}" -annotate +10+10 "$u_text" ${tg_config_dir}/${file_name}2
					result=$(curl -s "${tele_url}/sendPhoto" \
								-F chat_id="${chat_id}" \
								-F photo=@${tg_config_dir}/${file_name}2
							)
					echo $result
				
					rm -rf ${tg_config_dir}/${file_name}
					rm -rf ${tg_config_dir}/${file_name}2	
				fi
			fi
		fi  



		last_id=$(($last_id + 1))            
		echo $last_id > $last_id_file
			
		echo -e "\n: ${text}"
    done
}

function chk_user(){
	local usr=$1
	dat_stat=""
	u_data=`cat $users_data_file`
	user_stat=$(echo $u_data | jq  -r ".users[] | select(.user_id==\"${usr}\")")
	
	u_mode=$(echo $user_stat | jq -r ".mode")
	u_fsize=$(echo $user_stat | jq -r ".text.font_size")
    u_color=$(echo $user_stat | jq -r ".text.color")
    u_position=$(echo $user_stat | jq -r ".text.position")
    u_text=$(echo $user_stat | jq -r ".text.text")
	
	up_position=$(echo $user_stat | jq -r ".picture.position")
	up_opacity=$(echo $user_stat | jq -r ".picture.opacity")
	up_file=$(echo $user_stat | jq -r ".picture.file")
}

loop_core
