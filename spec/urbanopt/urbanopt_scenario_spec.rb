# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-scenario-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../spec_helper'
require_relative '../files/example_feature_file'
require 'json'
require 'json-schema'
RSpec.describe URBANopt::Scenario do
  @@logger ||= URBANopt::Reporting::DefaultReports.logger

  it 'has a version number' do
    expect(URBANopt::Scenario::VERSION).not_to be nil
  end

  it 'has a logger' do
    expect(URBANopt::Scenario.logger).not_to be nil
    current_level = URBANopt::Scenario.logger.level
    URBANopt::Scenario.logger.level = Logger::DEBUG
    expect(URBANopt::Scenario.logger.level).to eq Logger::DEBUG
    URBANopt::Scenario.logger.level = current_level
  end

  it 'can run a scenario' do
    name = 'example_scenario'

    # copy all files into test directory
    root_dir = File.join(File.dirname(__FILE__), '../test')
    Dir.mkdir(root_dir) unless File.exist?(root_dir)
    run_dir = File.join(File.dirname(__FILE__), '../test/example_scenario/')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../files/example_feature_file.json'), File.join(File.dirname(__FILE__), '../test/example_feature_file.json'))
    feature_file_path = File.join(File.dirname(__FILE__), '../test/example_feature_file.json')
    FileUtils.cp_r(File.join(File.dirname(__FILE__), '../files/mappers'), File.join(File.dirname(__FILE__), '../test/mappers'), remove_destination: true)
    FileUtils.cp_r(File.join(File.dirname(__FILE__), '../files/weather'), File.join(File.dirname(__FILE__), '../test/weather'), remove_destination: true)
    mapper_files_dir = File.join(File.dirname(__FILE__), '../test/mappers/')
    FileUtils.cp(File.join(File.dirname(__FILE__), '../files/example_scenario.csv'), File.join(File.dirname(__FILE__), '../test/example_scenario.csv'))
    csv_file = File.join(File.dirname(__FILE__), '../test/example_scenario.csv')
    num_header_rows = 1

    FileUtils.cp(File.join(File.dirname(__FILE__), '../files/Gemfile'), File.join(File.dirname(__FILE__), '../test/Gemfile'))

    # write a runner.conf in project dir
    options = { gemfile_path: File.join(File.dirname(__FILE__), '../test/Gemfile'), bundle_install_path: File.join(File.dirname(__FILE__), '../test/.bundle/install') }
    File.open(File.join(root_dir, 'runner.conf'), 'w') do |f|
      f.write(options.to_json)
    end

    feature_file = ExampleFeatureFile.new(feature_file_path)
    expect(feature_file.features.size).to eq(3)
    expect(feature_file.get_feature_by_id('1')).not_to be_nil
    expect(feature_file.get_feature_by_id('2')).not_to be_nil
    expect(feature_file.get_feature_by_id('3')).not_to be_nil
    expect(feature_file.get_feature_by_id('4')).to be_nil

    # create a new ScenarioCSV, we could create many of these in a project
    scenario = URBANopt::Scenario::ScenarioCSV.new(name, root_dir, run_dir, feature_file, mapper_files_dir, csv_file, num_header_rows)
    expect(scenario.name).to eq(name)
    expect(scenario.root_dir).to eq(root_dir)
    expect(scenario.run_dir).to eq(run_dir)
    expect(scenario.feature_file.path).to eq(feature_file.path)
    expect(scenario.mapper_files_dir).to eq(mapper_files_dir)
    expect(scenario.csv_file).to eq(csv_file)
    expect(scenario.num_header_rows).to eq(1)

    # set clear_results to be false if you want the tests to run faster
    clear_results = true
    scenario.clear if clear_results

    simulation_dirs = scenario.simulation_dirs
    expect(simulation_dirs.size).to eq(3)
    expect(simulation_dirs[0].features.size).to eq(1)
    expect(simulation_dirs[0].feature_names.size).to eq(1)
    expect(simulation_dirs[0].features[0].id).to eq('1')
    expect(simulation_dirs[0].feature_names[0]).to eq('Building 1')
    expect(simulation_dirs[0].mapper_class).to eq('URBANopt::Scenario::TestMapper1')
    expect(simulation_dirs[0].run_dir).to eq(File.join(run_dir, '1/'))

    if clear_results
      expect(File.exist?(simulation_dirs[0].run_dir)).to be false
      expect(File.exist?(simulation_dirs[1].run_dir)).to be false
      expect(File.exist?(simulation_dirs[2].run_dir)).to be false
    end

    # create a ScenarioRunnerOSW to run the ScenarioCSV

    scenario_runner = URBANopt::Scenario::ScenarioRunnerOSW.new

    scenario_runner.create_simulation_files(scenario, clear_results)
    expect(File.exist?(simulation_dirs[0].run_dir)).to be true
    expect(File.exist?(simulation_dirs[1].run_dir)).to be true
    expect(File.exist?(simulation_dirs[2].run_dir)).to be true

    # pass Gemfile and bundle paths to extension gem runner, otherwise it will use this gem's and that doesn't work b/c of native gems
    options = { gemfile_path: File.join(File.dirname(__FILE__), '../test/Gemfile'), bundle_install_path: File.join(File.dirname(__FILE__), '../test/.bundle/install'), skip_config: false }
    simulation_dirs = scenario_runner.run(scenario, false, options)
    if clear_results
      expect(simulation_dirs.size).to eq(3)
      expect(simulation_dirs[0].in_osw_path).to eq(File.join(run_dir, '1/in.osw'))
      expect(simulation_dirs[1].in_osw_path).to eq(File.join(run_dir, '2/in.osw'))
      expect(simulation_dirs[2].in_osw_path).to eq(File.join(run_dir, '3/in.osw'))
    end

    failures = []
    simulation_dirs.each do |simulation_dir|
      run_dir = simulation_dir.run_dir
      simulation_status = simulation_dir.simulation_status
      puts "run_dir = #{run_dir}, simulation_status = #{simulation_status}"
      if simulation_dir.simulation_status != 'Complete'
        failures << run_dir
      end
    end

    expect(failures).to be_empty, "the following directories failed to run [#{failures.join(', ')}]"

    # expect run_status.json to exist
    expect(File.exist?(File.join(scenario.run_dir, 'run_status.json'))).to be true

    default_post_processor = URBANopt::Scenario::ScenarioDefaultPostProcessor.new(scenario)
    $scenario_result = default_post_processor.run

    # save scenario result
    $scenario_result.save

    # create scenario sql db file
    # default_post_processor.create_scenario_db_file
    # expect default_scenario_report.db to exist
    # expect(File.exist?(File.join(scenario.run_dir, 'default_scenario_report.db'))).to be true

    ### save feature reports
    $scenario_result.feature_reports.each(&:save_feature_report)

    ## Add test assertions on scenario_result
    # Check scenario_report JSON file

    # Read json file
    scenario_json_file = File.open($scenario_result.json_path)
    data = JSON.parse(File.read(scenario_json_file))

    # Program results check
    expect(data['scenario_report']['program']['site_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['site_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['site_area_sqft']
    expect(data['scenario_report']['program']['floor_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['floor_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['floor_area_sqft']
    expect(data['scenario_report']['program']['conditioned_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['conditioned_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['conditioned_area_sqft']
    expect(data['scenario_report']['program']['unconditioned_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['unconditioned_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['unconditioned_area_sqft']
    expect(data['scenario_report']['program']['footprint_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['footprint_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['footprint_area_sqft']
    expect(data['scenario_report']['program']['maximum_roof_height_ft']).to eq(data['feature_reports'].map { |h| h['program']['maximum_roof_height_ft'] }.max) if data['scenario_report']['program']['maximum_roof_height_ft']
    expect(data['scenario_report']['program']['maximum_number_of_stories']).to eq(data['feature_reports'].map { |h| h['program']['maximum_number_of_stories'] }.max) if data['scenario_report']['program']['maximum_number_of_stories']
    expect(data['scenario_report']['program']['maximum_number_of_stories_above_ground']).to eq(data['feature_reports'].map { |h| h['program']['maximum_number_of_stories_above_ground'] }.max) if data['scenario_report']['program']['maximum_number_of_stories_above_ground']
    expect(data['scenario_report']['program']['parking_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['parking_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['parking_area_sqft']
    expect(data['scenario_report']['program']['number_of_parking_spaces']).to eq(data['feature_reports'].map { |h| h['program']['number_of_parking_spaces'] }.reduce(:+)) if data['scenario_report']['program']['number_of_parking_spaces']
    expect(data['scenario_report']['program']['number_of_parking_spaces_charging']).to eq(data['feature_reports'].map { |h| h['program']['number_of_parking_spaces_charging'] }.reduce(:+)) if data['scenario_report']['program']['number_of_parking_spaces_charging']
    expect(data['scenario_report']['program']['parking_footprint_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['parking_footprint_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['parking_footprint_area_sqft']
    expect(data['scenario_report']['program']['maximum_parking_height_ft']).to eq(data['feature_reports'].map { |h| h['program']['maximum_parking_height_ft'] }.max) if data['scenario_report']['program']['maximum_parking_height_ft']
    expect(data['scenario_report']['program']['maximum_number_of_parking_stories']).to eq(data['feature_reports'].map { |h| h['program']['maximum_number_of_parking_stories'] }.max) if data['scenario_report']['program']['maximum_number_of_parking_stories']
    expect(data['scenario_report']['program']['maximum_number_of_parking_stories_above_ground']).to eq(data['feature_reports'].map { |h| h['program']['maximum_number_of_parking_stories_above_ground'] }.max) if data['scenario_report']['program']['maximum_number_of_parking_stories_above_ground']
    expect(data['scenario_report']['program']['number_of_residential_units']).to eq(data['feature_reports'].map { |h| h['program']['number_of_residential_units'] }.reduce(:+)) if data['scenario_report']['program']['number_of_residential_units']

    expect(data['scenario_report']['program']['window_area_sqft']['north_window_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['window_area_sqft']['north_window_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['window_area_sqft']['north_window_area_sqft']
    expect(data['scenario_report']['program']['window_area_sqft']['south_window_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['window_area_sqft']['south_window_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['window_area_sqft']['south_window_area_sqft']
    expect(data['scenario_report']['program']['window_area_sqft']['east_window_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['window_area_sqft']['east_window_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['window_area_sqft']['east_window_area_sqft']
    expect(data['scenario_report']['program']['window_area_sqft']['west_window_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['window_area_sqft']['west_window_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['window_area_sqft']['west_window_area_sqft']
    expect(data['scenario_report']['program']['window_area_sqft']['total_window_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['window_area_sqft']['total_window_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['window_area_sqft']['total_window_area_sqft']

    expect(data['scenario_report']['program']['wall_area_sqft']['north_wall_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['wall_area_sqft']['north_wall_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['wall_area_sqft']['north_wall_area_sqft']
    expect(data['scenario_report']['program']['wall_area_sqft']['south_wall_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['wall_area_sqft']['south_wall_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['wall_area_sqft']['south_wall_area_sqft']
    expect(data['scenario_report']['program']['wall_area_sqft']['east_wall_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['wall_area_sqft']['east_wall_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['wall_area_sqft']['east_wall_area_sqft']
    expect(data['scenario_report']['program']['wall_area_sqft']['west_wall_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['wall_area_sqft']['west_wall_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['wall_area_sqft']['west_wall_area_sqft']
    expect(data['scenario_report']['program']['wall_area_sqft']['total_wall_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['wall_area_sqft']['total_wall_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['wall_area_sqft']['total_wall_area_sqft']

    expect(data['scenario_report']['program']['roof_area_sqft']['equipment_roof_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['roof_area_sqft']['equipment_roof_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['roof_area_sqft']['equipment_roof_area_sqft']
    expect(data['scenario_report']['program']['roof_area_sqft']['photovoltaic_roof_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['roof_area_sqft']['photovoltaic_roof_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['roof_area_sqft']['photovoltaic_roof_area_sqft']
    expect(data['scenario_report']['program']['roof_area_sqft']['available_roof_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['roof_area_sqft']['available_roof_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['roof_area_sqft']['available_roof_area_sqft']
    expect(data['scenario_report']['program']['roof_area_sqft']['total_roof_area_sqft']).to eq(data['feature_reports'].map { |h| h['program']['roof_area_sqft']['total_roof_area_sqft'] }.reduce(:+)) if data['scenario_report']['program']['roof_area_sqft']['total_roof_area_sqft']

    # Reporting periods results check
    expect(data['scenario_report']['reporting_periods'][0]['total_site_energy_kwh']).to eq(data['feature_reports'].map { |h| h['reporting_periods'][0]['total_site_energy_kwh'] }.reduce(:+))

    ##
    # validate all results against schema
    ##

    # initialize validator class
    validator = URBANopt::Reporting::DefaultReports::Validator.new

    # Get scenario schema hash
    schema = validator.schema

    # Read scenario json file and validated againt schema
    scenario_json = JSON.parse(File.read(scenario_json_file))

    @@logger.info("Schema Validation Errors: #{JSON::Validator.fully_validate(schema, scenario_json)}")
    expect(JSON::Validator.fully_validate(schema, scenario_json).empty?).to be true

    # close json file
    scenario_json_file.close

    # Read scenario csv file and validate against scenario CSV schema
    scenario_csv_headers = CSV.open(File.expand_path($scenario_result.csv_path, File.dirname(__FILE__)), &:readline)
    # strip the units partial string from the scenario_csv_header since these units can change
    scenario_csv_headers_with_no_units = []
    scenario_csv_headers.each do |x|
      scenario_csv_headers_with_no_units << x.split('(')[0]
    end

    scenario_csv_schema_headers = validator.csv_headers
    expect((scenario_csv_headers_with_no_units & scenario_csv_schema_headers)).to eq(scenario_csv_headers_with_no_units)

    # Read feature_reprot json file and validate against schema
    Dir["#{File.dirname(__FILE__)}/../**/*default_feature_reports.json"].each do |json_file|
      feature_json = JSON.parse(File.read(json_file))
      expect(JSON::Validator.fully_validate(schema[:definitions][:FeatureReport][:properties], feature_json).empty?).to be true
    end
  end

  it 'can integrate opendss results' do
    # generate opendss results for testing
    opendss_results_source = File.join(File.dirname(__FILE__), '../files/opendss_outputs/')
    opendss_results_destination = File.join(File.dirname(__FILE__), '../test/example_scenario')
    FileUtils.copy_entry opendss_results_source, opendss_results_destination
    # post_process opendss results
    opendss_post_processor = URBANopt::Scenario::OpenDSSPostProcessor.new($scenario_result, 'opendss')
    opendss_post_processor.run
  end

  it 'can integrate disco results' do
    # generate disco results for testing
    disco_results_source = File.join(File.dirname(__FILE__), '../files/disco_outputs/')
    disco_results_destination = File.join(File.dirname(__FILE__), '../test/example_scenario')
    FileUtils.copy_entry disco_results_source, disco_results_destination
    # post_process disco results
    disco_post_processor = URBANopt::Scenario::DISCOPostProcessor.new($scenario_result, 'disco')
    disco_post_processor.run
  end
end
