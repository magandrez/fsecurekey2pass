#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Copyright (C) 2017 Manuel González <manuel@digitalfoodie.fm>.
# All Rights Reserved. This file is licensed under GPLv2+.
#
# F-Secure KEY Importer
#
# Reads files exported from F-Secure (.fsk) and imports them into pass.
# The export file is a JSON formatted file like:
#
# {
#  "data": {
#     <GUID>: {
#       "passwordList": <Array>,
#       "style": <String>,
#       "rev": <Integer>,
#       "favorite": <Integer>,
#       "url": <String>,
#       "creditNumber": <String>,
#       "type": <Integer>,
#       "creditExpiry": <String>,
#       "notes": <String>,
#       "password": <String>, 
#       "creditCvv": <Integer>,
#       "service": <String>,
#       "username": <String>,
#       "color": <String>
#     } 
#   }
# }
#
# Supports importing metadata, adding them with `pass insert --multiline`

require "optparse"
require "logger"
require "json"

options = {}
options[:force] = false
options[:group] = 'personal'
options[:notes] = true

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{opts.program_name}.rb [options] filename"
  opts.on_tail("-h", "--help", "Displays this screen") { puts opts; exit }
  opts.on("-f", "--force",
          "Overrides existing passwords") do
    options.force = true
  end
  opts.on("-g", "--group [FOLDER]",
          "Places passwords into FOLDER") do |group|
    options.group = group
  end
  opts.on("-n", "--[no-]notes",
          "Imports notes (--multiline option in pass)") do |meta|
    options.notes = notes
  end
  begin
    opts.parse!
  rescue OptionParser::InvalidOption
    puts optparse
    exit
  end
end

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

def run
  filename = ARGV.pop # last parameter being the filename  
  unless valid_file?(filename)
    LOGGER.error "Missing filename to import. " \
      "Read `#{__FILE__} --help` for more information "
    exit 1
  else
    LOGGER.info "Started the import of file #{filename} into pass."
  end

  unless valid_json?(filename)
    exit 1
  end

  blob = load_file(filename)
  data = blob[:data].to_a

  LOGGER.info "Read #{data.count} accounts."

  # Save the passwords
  data.each do |pass|
    IO.popen("pass insert #{"-f " if options.force}-m \"#{pass[:username]}\" > /dev/null", "w") do |io|
      io.puts pass[:password]
      if options.notes
        io.puts "LOGIN: #{pass[:username]}" unless pass[:username].to_s.empty?
        io.puts "URL: #{pass[:url]}" unless pass[:url].to_s.empty?
        io.puts pass[:notes] unless pass[:notes].to_s.empty?
      end
    end
    if $? == 0
      LOGGER.info "Imported #{pass[:service]}"
    else
      LOGGER.error "Failed to import #{pass[:name]}"
      errors << pass
    end
  end
end

def load_file(filename)
  file = File.read(filename)
  hash = JSON.parse(file)
  return symbolize_keys(hash)
end

def symbolize_keys(hash)
  hash.inject({}){|new_hash, key_value|
    key, value = key_value
    value = symbolize_keys(value) if value.is_a?(Hash)
    new_hash[key.to_sym] = value
    new_hash
  }
end

def valid_file?(filename)
  return false unless filename
  return false unless File.file?(filename)
  return true
end

def valid_json?(filename)
  file = File.read(filename)
  JSON.parse(file)
  return true
  rescue JSON::ParserError => e
    LOGGER.error "Malformed JSON: #{e}" 
    return false
end

run
