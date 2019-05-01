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

require 'urbanopt/scenario/scenario_post_processor_base'
require 'urbanopt/scenario/default_reports'

require 'csv'
require 'json'
require 'fileutils'

module URBANopt
  module Scenario
    class ScenarioDefaultPostProcessor < ScenarioPostProcessorBase
    
      ##
      # ScenarioPostProcessorBase post-processes a scenario to create scenario level results
      ##
      def initialize(scenario)
        super(scenario)
        
        @scenario_result = URBANopt::Scenario::DefaultReports::ScenarioReport.new(scenario)
      end
      
      ##
      # Run the post processor on this Scenario
      ##
      def run
        @scenario_result = URBANopt::Scenario::DefaultReports::ScenarioReport.new(scenario)
      
        # this run method adds all the simulation_dirs, you can extend it to do more custom stuff
        scenario.simulation_dirs.each do |simulation_dir|
          add_simulation_dir(simulation_dir)
        end
        
        return @scenario_result
      end
      
      ##
      # Add results from a simulation_dir to this result
      ##
      def add_simulation_dir(simulation_dir)
        feature_reports = URBANopt::Scenario::DefaultReports::FeatureReport::from_simulation_dir(simulation_dir)
        
        feature_reports.each do |feature_report|
          @scenario_result.add_feature_report(feature_report)
        end
        
        return feature_reports
      end

      ##
      # Save scenario result
      ##
      def save
        @scenario_result.save
        
        return @scenario_result
        
        # TODO: Rawad, save the timeseries data to a CSV and the summary data to JSON

        File.open( File.join(@scenario.run_dir, 'scenario_out.json'), 'w') do |file|
          file << "{\"Results\": 1}"
        end

        # Get input files
        input_files = Dir.glob("**/*.csv")
        #input_files = Dir["C:/gitrepos/urbanopt-scenario-gem/spec/test/example_scenario/**/*eplusssz.csv"]

        # Collect/combine headers
        all_headers = input_files.reduce([]) do |all_headers, file|
          header_line = File.open(file, &:gets)     # grab first line
          all_headers | CSV.parse_line(header_line) # parse headers and merge with known ones
        end

        File.open( File.join(@scenario.run_dir, 'scenario_timeseries.csv'), 'w') do |file|
          # Write all headers
          file << all_headers

          # Write rows from each file
          input_files.each do |file|
            CSV.foreach(file, headers: true) do |row|
              file << all_headers.map { |header| row[header] }
            end
          end
        end
      end

    end
  end
end
