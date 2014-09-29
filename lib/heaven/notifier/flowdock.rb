module Heaven
  module Notifier
    # A notifier for flowdock
    class Flowdock < Notifier::Default
      def deliver(message)
        Rails.logger.info "flowdock: #{message}"

        params = {
          content: message,
          tags: tags
        }
        if !thread_id.blank?
          params[:thread_id] = thread_id
        elsif !message_id.blank?
          params[:message_id] = message_id
        end
        if use_push_api?
          flow.push_to_chat(params)
        else
          params[:flow] = chat_room
          client.chat_message(params)
        end
      end

      def flow
        @flow ||= ::Flowdock::Flow.new(api_token: flowdock_flow_api_token, external_user_name: flowdock_external_user_name)
      end

      def client
        @client ||= ::Flowdock::Client.new(api_token: flowdock_user_api_token)
      end

      def thread_id
        deployment_payload["notify"]["thread_id"]
      end

      def message_id
        deployment_payload["notify"]["message_id"]
      end

      def repository_link(path = "")
        "#{repo_name}#{maybe_ref} (#{repo_url(path)})"
      end

      def user_link
        "@#{chat_user}"
      end

      def output_link
        target_url
      end

      def tags
        ['deploy', environment, flowdock_project_name, state].compact
      end

      def flowdock_project_name
        deployment_payload["config"]["flowdock_project_name"]
      end

      def maybe_ref
        if ref == repo_default_branch then '' else "/#{ref}" end
      end

      def default_message
        case state
        when "success"
          "Deployment done! Output: #{output_link}"
        when "failure"
          "Deployment failed. Output: #{output_link}"
        when "error"
          "Deployment has errors. Output: #{output_link}"
        when "pending"
          "Deployment of #{repository_link("/tree/#{ref}")} to #{environment} started."
        else
          puts "Unhandled deployment state, #{state}"
        end
      end

      private

      def use_push_api?
        flowdock_user_api_token.blank?
      end

      def flowdock_flow_api_token
        ENV["FLOWDOCK_FLOW_API_TOKEN"]
      end

      def flowdock_external_user_name
        ENV["FLOWDOCK_EXTERNAL_USER_NAME"]
      end

      def flowdock_user_api_token
        ENV["FLOWDOCK_USER_API_TOKEN"]
      end

      def repo_default_branch
        payload["repository"]["default_branch"]
      end
    end
  end
end
