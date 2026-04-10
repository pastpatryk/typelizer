# frozen_string_literal: true

RSpec.describe Typelizer do
  let(:output_dir) { Typelizer::Config.default_output_dir }
  let(:custom_output_dir) { Rails.root.join("app/javascript/types/custom_output") }

  around(:each) do |example|
    FileUtils.rmtree(output_dir)
    FileUtils.rmtree(custom_output_dir)
    example.run
    FileUtils.rmtree(output_dir)
    FileUtils.rmtree(custom_output_dir)
  end

  it "enabled? returns true when Rails.env is development but ENV['RAILS_ENV'] is nil" do
    original_typelizer = ENV.delete("TYPELIZER")
    original_rails_env = ENV.delete("RAILS_ENV")
    original_rack_env = ENV.delete("RACK_ENV")
    Typelizer.instance_variable_set(:@legacy_env_migrated, nil)

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

    expect(Typelizer.enabled?).to be true
  ensure
    ENV["TYPELIZER"] = original_typelizer if original_typelizer
    ENV["RAILS_ENV"] = original_rails_env if original_rails_env
    ENV["RACK_ENV"] = original_rack_env if original_rack_env
    Typelizer.instance_variable_set(:@legacy_env_migrated, nil)
  end

  it "has a rake task available", aggregate_failures: true do
    Rails.application.load_tasks
    expect { Rake::Task["typelizer:generate"].invoke }.not_to raise_error

    # check all generated files are equal to the snapshots
    all_files = output_dir.glob("**/*.ts") + custom_output_dir.glob("**/*.ts")
    all_files.each do |file|
      expect(file.read).to match_snapshot(file.basename)
    end
  end
end
