module QueryRequest
    extend ActiveSupport::Concern
    @page_access_token = nil
    
    def self.received_authentication event
        sender_id = event["sender"]["id"]
        recipient_id = event["recipient"]["id"]
        time_of_auth = event["timestamp"]
        pass_through_param = event["optin"]["ref"]
      
        Rails.logger.info "Received authentication for user #{sender_id} and
            page #{recipient_id} with pass through param #{pass_through_param} at #{time_of_auth}"
        send_text_message(sender_id,"Authentication Successful")
    end
  
    def self.received_message event
        sender_id = event["sender"]["id"]
        recipient_id = event["recipient"]["id"]
        time_of_message = event["timestamp"]
        message = event["message"]
        Rails.logger.info "Received message for user #{sender_id} and page #{recipient_id}
            at #{time_of_message}"
        
        message_id = message["id"]
        message_text = message["text"]
        message_attachments = message["attachments"]
        
        if message_text
            get_all_definitions(sender_id, message_text)
        else
            send_text_message(sender_id,"Message With Attachment Received")
        end
    end
    
    def self.received_delivery_confirmation event
        sender_id = event["sender"]["id"]
        recipient_id = event["recipient"]["id"]
        delivery = event["delivery"]
        message_ids = delivery["mids"]
        watermark = delivery["watermark"]
        sequence_number = delivery["seq"]
        if message_ids
            message_ids.each do |message_id|
                Rails.logger.info "Received delivery confirmation 
                    for message ID: #{message_id}"
            end
        end
        Rails.logger.info "All message before #{watermark} were delivered."
    end
    
    def self.received_postback event
        sender_id = event["sender"]["id"]
        recipient_id = event["recipient"]["id"]
        time_of_postback = event["timestamp"]
        payload = JSON.parse(event["postback"]["payload"])
        
        if payload["service"] == "definition"
            get_specific_definition(sender_id, payload)
        else
            send_text_message(sender_id,"Postback Called")
        end
        
        Rails.logger.info "Received postback for user #{sender_id} and page 
            #{recipient_id} with payload #{payload} at #{time_of_postback}"
    end
    
    def self.send_text_message(recipient_id,message_text)
        message_data ={
            recipient:{
                id: recipient_id
            },
            message:{
                text: message_text
            }
        }
        call_send_api(message_data)
    end
    
    def self.send_generic_message( recipient_id, elements)
        message_data = {
            "recipient": {
                "id": recipient_id
            },
            "message": {
                "attachment": {
                    "type": "template",
                    "payload": {
                        "template_type": "generic",
                        "elements": elements
                    }
                }
            }
        }
        call_send_api message_data
    end
    
    def self.get_definition(word)
        begin
            headers = { 
                "X-Mashape-Key" => "KVR4tIrf2tmshReqZiIrsNHXu6sEp12E2QxjsnV1fTtjpiXYQj",
                "Accept" => "application/json"
            }
            response = RestClient.get "https://wordsapiv1.p.mashape.com/words/#{word}/definitions", headers
            response = JSON.parse(response)
        rescue
            response = nil
        end
        response
    end
    
    def self.get_all_definitions( recipient_id, word)
        response = get_definition(word)
        if response
            definitions = response["definitions"].first(10)
            definition_elements = []
            
            definitions.each_with_index do |definition, index|
                element = {
                    "title": definition["partOfSpeech"],
                    "subtitle": definition["definition"]
                }
                if element[:subtitle] and element[:subtitle].length > 80
                    element[:buttons] = [
                        {
                            "type":"postback",
                            "title": "read full",
                            "payload": {"service": "definition", "word": word, "no": index}.to_json
                        }
                    ]
                end
                definition_elements.push(element)
            end
            send_generic_message recipient_id, definition_elements
        else
            send_text_message(recipient_id ,"No meaning found")
        end
    end
    
    def self.get_specific_definition(recipient_id, payload)
        response = get_definition(payload["word"])
        if response
            definition = response["definitions"][payload["no"]]
            send_text_message(recipient_id, definition["definition"])
        else
            send_text_message(recipient_id ,"No meaning found")
        end
    end

    
    def self.call_send_api message_data
        response = RestClient.post "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_access_token}",
        message_data.to_json,
        :content_type => 'application/json',
        :accept => 'application/json'
   
        Rails.logger.info "Response error #{response}"
    end
    
end
