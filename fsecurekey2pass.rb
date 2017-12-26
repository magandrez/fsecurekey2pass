#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Copyright (C) 2017 Manuel González <manuel@foodie.fm>.
# All Rights Reserved. This file is licensed under GPLv2+.
#
# F-Secure KEY importer to zx2c4's password-store (the standard Unix password manager)
#
# Reads files exported from F-Secure (.fsk) and imports them into pass.
# The export file is a JSON formatted file. The script has been put together
# to use only standard Ruby libraries (i.e.: no Gemfile, bundler, etc)
# Supports importing metadata, via `pass insert --multiline`.

require "optparse"
require "logger"
require "json"
require "pry"
require "open3"

options = {}
options[:force] = false
options[:group] = "personal"
options[:notes] = true

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{opts.program_name}.rb [options] filename"
  opts.on_tail("-h", "--help", "Displays this screen") { puts opts; exit }
  opts.on("-f", "--force",
          "Overrides existing passwords") do
    options[:force] = true
  end
  opts.on("-g", "--group [FOLDER]",
          "Places passwords into FOLDER") do |group|
    options[:group] = group
  end
  begin
    opts.parse!
  rescue OptionParser::InvalidOption
    puts optparse
    exit
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

# Main
start_time = Time.now
LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

filename = ARGV.pop # last parameter being the filename
# Validate data input
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

# Massage data
blob = load_file(filename)
data = []
blob[:data].each{|_key, value| data.push(value)}

LOGGER.info "Read #{data.count} accounts. Starting import..."

# Save the accounts
data.each do |pass|
  cmd = "pass insert -m "
  cmd << "-f " if options[:force]
  cmd << "'#{options[:group]}/#{pass[:service]}'\n"
  Open3.popen3(cmd) do |i,_o,e,_t|
    i.puts pass[:password]
    i.puts "URL: #{pass[:url]}" unless pass[:url].empty?
    i.puts "Username: #{pass[:username]}" unless pass[:username].empty?
    i.puts "Notes: #{pass[:notes]}" unless pass[:notes].empty?
    i.puts "Card number: #{pass[:creditNumber]}" unless pass[:creditNumber].to_s.empty?
    i.puts "Expiry date: #{pass[:creditExpiry]}" unless pass[:creditExpiry].to_s.empty?
    i.puts "CVV: #{pass[:creditCvv]}" unless pass[:creditCvv].to_s.empty?
    i.close_write
    error = e.read
    LOGGER.error "An error occurred with account #{pass[:service]}: #{error}" unless error.empty?
  end
end

end_time = Time.now
LOGGER.info "Finished importing accounts into pass. "\
  "Import took #{end_time - start_time} seconds."
