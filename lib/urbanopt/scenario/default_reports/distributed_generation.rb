#*********************************************************************************
# URBANopt, Copyright (c) 2019, Alliance for Sustainable Energy, LLC, and other 
# contributors. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this list 
# of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice, this 
# list of conditions and the following disclaimer in the documentation and/or other 
# materials provided with the distribution.
# 
# Neither the name of the copyright holder nor the names of its contributors may be 
# used to endorse or promote products derived from this software without specific 
# prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
# OF THE POSSIBILITY OF SUCH DAMAGE.
#*********************************************************************************

require 'json'
require 'urbanopt/scenario/default_reports/pv'
require 'urbanopt/scenario/default_reports/wind'
require 'urbanopt/scenario/default_reports/generator'
require 'urbanopt/scenario/default_reports/storage'
require 'json-schema'

module URBANopt
  module Scenario
    module DefaultReports
      class DistributedGeneration 

        attr_accessor :lcc_us_dollars, :npv_us_dollars, :year_one_energy_cost_us_dollars, :year_one_demand_cost_us_dollars, :year_one_demand_cost_us_dollars, :year_one_bill_us_dollars, :total_energy_cost_us_dollars, :pv, :wind, :generator, :storage
        
        ##
        # Intialize reporting period attributes
        ##
        # perform initialization functions
        def initialize(hash = {})
          
          hash.delete_if {|k, v| v.nil?}
            
          @lcc_us_dollars = hash[:lcc_us_dollars]
          @npv_us_dollars = hash[:npv_us_dollars]
          @year_one_energy_cost_us_dollars = hash[:year_one_energy_cost_us_dollars]
          @year_one_demand_cost_us_dollars = hash[:year_one_demand_cost_us_dollars]
          @year_one_bill_us_dollars = hash[:year_one_bill_us_dollars]
          @total_energy_cost_us_dollars = hash[:total_energy_cost_us_dollars]
          
          @pv = PV.new(hash[:pv] || {})
          @wind = Wind.new(hash[:wind] || {})
          @generator = Generator.new(hash[:generator] || {})
          @storage = Storage.new(hash[:storage] || {})
          
          
          # initialize class variables @@validator and @@schema
          @@validator ||= Validator.new
          @@schema ||= @@validator.schema
          
          # initialize @@logger
          @@logger ||= URBANopt::Scenario::DefaultReports.logger
        end
        
      
        ##
        # Convert to a Hash equivalent for JSON serialization
        ##
        def to_hash
          
          result = {}

          result[:lcc_us_dollars] =  @lcc_us_dollars if @lcc_us_dollars
          result[:npv_us_dollars] = @npv_us_dollars if @npv_us_dollars
          result[:year_one_energy_cost_us_dollars] = @year_one_energy_cost_us_dollars if @year_one_energy_cost_us_dollars
          result[:year_one_demand_cost_us_dollars] = @year_one_demand_cost_us_dollars if @year_one_demand_cost_us_dollars
          result[:year_one_bill_us_dollars] = @year_one_bill_us_dollars if @year_one_bill_us_dollars 
          result[:total_energy_cost_us_dollars] = @total_energy_cost_us_dollars if @total_energy_cost_us_dollars 
          result[:pv] = @pv.to_hash if @pv
          result[:wind] = @wind.to_hash if @wind
          result[:generator] = @generator.to_hash if @generator
          result[:storage] = @storage.to_hash if @storage
          
          return result
        end

        ### get keys ...not needed
        # def self.get_all_keys(h)
        #   h.each_with_object([]){|(k,v),a| v.is_a?(Hash) ? a.push(k,*get_all_keys(v)) : a << k }
        # end

        ##
        # Add up old and new values
        ##
        def self.add_values(existing_value, new_value)
          if existing_value && new_value
            existing_value += new_value
          elsif new_value
            existing_value = new_value
          end
          return existing_value
        end
        
        ##
        # Merge a distributed generation system with a new system
        ## 
        def self.merge_distributed_generation(existing_dgen, new_dgen)
          
          existing_dgen.lcc_us_dollars = add_values(existing_dgen.lcc_us_dollars, new_dgen.lcc_us_dollars)
          existing_dgen.npv_us_dollars = add_values(existing_dgen.npv_us_dollars, new_dgen.npv_us_dollars)  
          existing_dgen.year_one_energy_cost_us_dollars = add_values(existing_dgen.year_one_energy_cost_us_dollars, new_dgen.year_one_energy_cost_us_dollars) 
          existing_dgen.year_one_demand_cost_us_dollars = add_values(existing_dgen.year_one_demand_cost_us_dollars, new_dgen.year_one_demand_cost_us_dollars)
          existing_dgen.year_one_bill_us_dollars = add_values(existing_dgen.year_one_bill_us_dollars, new_dgen.year_one_bill_us_dollars)
          existing_dgen.total_energy_cost_us_dollars = add_values(existing_dgen.total_energy_cost_us_dollars, new_dgen.total_energy_cost_us_dollars)
          
          existing_dgen.pv = PV.add_pv existing_dgen.pv, new_dgen.pv
          existing_dgen.wind = Wind.add_wind existing_dgen.wind, new_dgen.wind
          existing_dgen.generator = Generator.add_generator existing_dgen.generator, new_dgen.generator
          existing_dgen.storage = Storage.add_storage existing_dgen.storage, new_dgen.storage

          return existing_dgen
         
        end
        
        
      end
    end
  end
end
