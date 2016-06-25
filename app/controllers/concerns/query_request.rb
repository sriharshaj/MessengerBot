module QueryRequest
    extend ActiveSupport::Concern
    @page_access_token = "EAAPtidyFOdUBAGhf3jQ29kwnrDQNoONxSa6ZAljwqJSQ6tWbZCuHsRz4p3LcATSMW0ZCzwDIaKxJCCbPpycztEYaZBORlCQ0rQZCohumIuNmdk9NM5EARv2wcsvatJnvScZBvS90ZBUZAtTFIYZCQkuavs446QMzwqqLsMOqPYhuQeQZDZD"

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
            send_text_message(sender_id,message_text)
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
        payload = event["postback"]["payload"]
        
        Rails.logger.info "Received postback for user #{sender_id} and page 
            #{recipient_id} with payload #{payload} at #{time_of_postback}"
        send_text_message(sender_id,"Postback Called")
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
    
    def self.call_send_api message_data
        options ={
            query: {access_token: @page_access_token},
            body: message_data
        }
        response = HTTParty.post("https://graph.facebook.com/v2.6/me/messages",options)
        Rails.logger.info "Response code #{response.code}"
    end
    
end