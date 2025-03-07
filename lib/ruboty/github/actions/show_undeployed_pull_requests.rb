require 'pp'

module Ruboty
  module Github
    module Actions
      class ShowUndeployedPullRequests < Base
        def call
          case
          when !has_access_token?
            require_access_token
          else
            show
          end
        rescue Octokit::Unauthorized
          message.reply("Failed in authentication (401)")
        rescue Octokit::NotFound
          message.reply("Could not find that issue")
        rescue => exception
          raise exception
          message.reply("Failed by #{exception.class}")
        end

        private

        def show
          if merge_pull_requests.empty?
            message.reply 'No pull requests have been merged since the last deployment.'
          else
            merge_pull_requests.each do |text|
              m = text
                .gsub(/\AMerge pull request (\#\d+).*\n\n/) { "#{$1} " }
                .gsub(/(?![\r\n\t ])[[:cntrl:]]/, '')
              message.reply m
            end
          end
        end

        def merge_pull_requests
          @merge_pull_requests ||= commits[:commits].map {|commit|
            commit[:commit][:message]
          }.grep(/\AMerge pull request/)
        end

        def commits
          @commits ||= client.compare(repo, latest_deploy, 'master')
        end

        def latest_deploy
          ENV['LATEST_DEPLOY'] || 'release/main'
        end

        def repo
          message[:repo]
        end
      end
    end
  end
end
