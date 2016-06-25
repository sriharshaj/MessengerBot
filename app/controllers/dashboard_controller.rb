class DashboardController < ApplicationController
    before_action :set_token_access
    
    def webhook
        if params["hub.mode"] == 'subscribe' and params["hub.verify_token"] ==@validation_token
            render json: params["hub.challenge"]
        else
            render nothing: true,status: 403
        end
    end
    
    def webhook_post
        data = params
        if data["object"] == "page"
            data["entry"].each do |page_entry|
                page_id = page_entry["id"]
                time_of_event = page_entry["time"]
                page_entry["messaging"].each do |messaging_event|
                    if messaging_event["optin"]
                        QueryRequest.delay.received_authentication(messaging_event)
                    elsif messaging_event["message"]
                        QueryRequest.delay.received_message(messaging_event)
                    elsif messaging_event["delivery"]
                        QueryRequest.delay.received_delivery_confirmation(messaging_event)
                    elsif messaging_event["postback"]
                        QueryRequest.delay.received_postback(messaging_event)
                    end
                end
            end
        end
        render nothing: true,status: 200
    end
    
    private
        def set_token_access
            @app_secret = "ab458677cb781ca4e4abf67bf0e8ee39"
            @validation_token = "my_name_is_my_password"
        end
end
