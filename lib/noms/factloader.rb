#!/usr/bin/env ruby

#
# Copyright 2014 Evernote Corporation. All rights reserved.
# Copyright 2013 Proofpoint, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'noms/cmdb'
require 'yaml'

$version = NOMS::Factloader::VERSION
$me = 'factloader'

#
# = NAME
#
# factloader - Load facts from Puppet YAML files into Inventory
#
# = SYNOPSIS
#
#    factloader { --factpath path | file } [file [...]]
#       --nocheck-expiry  Don't check expiration date
#       --factpath        Specify directory full of *.yaml files
#       --trafficcontrol  Specify trafficcontrol parameter
#          url=           Specify trafficcontrol URL
#          username=      Specify trafficcontrol Username
#          password=      Specify trafficcontrol password
#       Other options as outlined in Optconfig
#
# = DESCRIPTION
#
# = AUTHOR
#
# Jeremy Brinkley, <jbrinkley@evernote.com>
# Isaac Finnegan, <ifinnegan@evernote.com>
#

class NOMS

end

class NOMS::Factloader

    def vrb(msg)
        if @logger and @logger.respond_to? :info
            @logger.info msg
        end
    end

    def wrn(msg)
        if @logger and @logger.respond_to? :warn
            @logger.warn msg
        end
    end

    def dbg(msg)
        if @opt['debug'] > 1
            if @logger and @logger.respond_to? :debug
                @logger.debug msg
            else
                puts "DBG(#{self.class}): #{msg}"
            end
        end
    end

    def get_facts(file)
        File.open(file, 'r') { |fh| YAML.load(fh).ivars }
    end

    def current?(fact)
        dbg "Considering #{fact['expiration']} vs #{Time.now()}"
        if $opt['check-expiry']
            fact['expiration'] > Time.now()
        else
            true
        end
    end

    def get_files(path)
        Dir.entries(path).select { |e| /\.yaml$/.match(e) }.map { |f|
            File.join(path, f) }
    end

    def gather_facts(files)
        dbg "Files: #{files.join(', ')}"
        facts = files.map { |f| File.open(f, 'r') { |fh| YAML.load(fh).ivars } }
        dbg "All facts: #{facts.inspect}"
        rfacts = facts.select { |fact| current?(fact) }.map { |fact| fact['values'] }
        dbg "Current facts: #{rfacts.inspect}"
        rfacts
    end

    def map_keys(keymap, factset)
        xmap = { }
        factset.each do |k, v|
            if keymap.has_key? k
                dbg "   mapping #{k} -> #{keymap[k]} = #{v}"
                xmap[keymap[k]] = v
            end
        end
        dbg "merging into #{xmap.inspect}"
        xmap.merge(factset)
    end

    def initialize(opt)
        # This is a CLI-ish class, uses top-level of
        # config
        @opt = opt
        @logger = opt['logger'] if opt['logger']

        if @opt['factpath'].nil?
            @files = [ ]
        else
            vrb "Scanning #{$opt['factpath']}"
            @files = get_files($opt['factpath'])
        end
    end

    def update_facts()

        cmdb = NOMS::CMDB.new(@opt)
        dbg "cmdb created with #{@opt.inspect}"
        facts.each do |rawfactset|
            factset = map_keys(@opt['keymap'], rawfactset).merge($opt['add'])
            id = factset['fqdn']
            vrb "Updating facts for #{id}"
            begin
                cmdb.tc_post(factset) unless $opt['dry-run']
            rescue => e
                wrn "Error updating facts for #{id}: #{e}"
            end
        end

    end

end
