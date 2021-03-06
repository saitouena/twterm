require 'curses'
require 'twterm/key_mapper/no_such_command'
require 'twterm/key_mapper/no_such_key'

module Twterm
  class KeyMapper
    class AbstractKeyMapper
      def initialize(dict)
        commands = self.class.commands

        dict ||= {}

        dict.keys.each do |k|
          raise NoSuchCommand.new(self.class.category, k) unless commands.include?(k)
        end

        @mappings = Hash[dict.map { |k, v| [k, translate(v)] }]
        @dict = dict
      end

      def [](key)
        raise NoSuchCommand.new(self.class.category, key) unless @mappings.keys.include?(key)
        @mappings[key]
      end

      def self.commands
        self::DEFAULT_MAPPINGS.keys
      end

      def to_h
        @dict
      end

      private

      def translate(key)
        case key
        when '!'..'}' then key
        when /\A\^([A-Z]?)\Z/ then $1.ord - 'A'.ord + 1
        when 'F1' then Curses::Key::F1
        when 'F2' then Curses::Key::F2
        when 'F3' then Curses::Key::F3
        when 'F4' then Curses::Key::F4
        when 'F5' then Curses::Key::F5
        when 'F6' then Curses::Key::F6
        when 'F7' then Curses::Key::F7
        when 'F8' then Curses::Key::F8
        when 'F9' then Curses::Key::F9
        when 'F10' then Curses::Key::F10
        when 'F11' then Curses::Key::F11
        when 'F12' then Curses::Key::F12
        else
          raise NoSuchKey.new(key)
        end
      end
    end
  end
end
