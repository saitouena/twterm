require 'twterm/publisher'
require 'twterm/event/notification/error'

module Twterm
  class Tweetbox
    class EmptyTextError < StandardError; end
    class InvalidCharactersError < StandardError; end
    class TextTooLongError < StandardError; end

    include Readline
    include Curses
    include Publisher

    def initialize(app, client)
      @app, @client = app, client
    end

    def compose
      ask_and_post("\e[1mCompose new Tweet\e[0m", '> ', -> body { body })
    end

    def quote(status)
      screen_name = app.user_repository.find(status.user_id).screen_name
      leading_text = "\e[1mQuoting @#{screen_name}'s Tweet\e[0m\n\n#{status.text}"
      prompt = '> '

      ask_and_post(leading_text, prompt, -> body { "#{body} #{status.url}" })
    end

    def reply(status)
      screen_name = app.user_repository.find(status.user_id).screen_name
      leading_text = "\e[1mReplying to @#{screen_name}\e[0m\n\n#{status.text}"
      prompt = "> @#{screen_name} "

      ask_and_post(leading_text, prompt, -> body { "@#{screen_name} #{body}" }, { in_reply_to_status_id: status.id })
    end

    private

    attr_reader :app, :client, :in_reply_to

    def ask(prompt, postprocessor, &cont)
      app.completion_manager.set_default_mode!

      thread = Thread.new do
        raw_text = ''

        loop do
          loop do
            line = (readline(prompt, true) || '').strip
            break if line.empty?

            if line.end_with?('\\')
              raw_text << line.chop.rstrip + "\n"
            else
              raw_text << line
              break
            end
          end

          puts "\n"

          text = postprocessor.call(raw_text)

          begin
            validate!(text)
            break
          rescue EmptyTextError
            break
          rescue InvalidCharactersError
            puts 'Text contains invalid characters'
          rescue TextTooLongError
            puts "Text is too long (#{text_length(text)} / 140 characters)"
          end

          puts "\n"
          raw_text = ''
        end

        reset
        cont.call(raw_text) unless raw_text.empty?
      end

      app.register_interruption_handler do
        thread.kill
        puts "\nCanceled"
        reset
      end

      thread.join
    end

    def ask_and_post(leading_text, prompt, postprocessor, options = {})
      close_screen
      puts "\e[H\e[2J#{leading_text}\n\n"
      ask(prompt, postprocessor) { |text| client.post(postprocessor.call(text), options) }
    end

    def reset
      reset_prog_mode
      sleep 0.1
      app.screen.refresh
    end

    def text_length(text)
      Twitter::Validation.tweet_length(text)
    end

    def validate!(text)
      case Twitter::Validation.tweet_invalid?(text)
      when :empty
        fail EmptyTextError
      when :invalid_characters
        fail InvalidCharactersError
      when :too_long
        fail TextTooLongError
      end
    end
  end
end
