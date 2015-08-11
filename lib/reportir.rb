require "reportir/version"
require 's3_uploader'
require 'aws-sdk'

#TODO: RSpec::Core::Formatters.register

module Reportir
  @@step = 0
  @@tests = [] # has to be array for front-end

  def upload_result_to_s3_as_static_site
    return upload_everything_to_s3 if upload_to_s3_possible?
    save_report_locally
  end

  def save_report_locally
    copy_template_to_temp_dir
    write_javascript_models
    save_final_markup
    puts "Upload to s3 not possible. Missing ENV vars. Report saved to #{local_root}"
  end

  def upload_everything_to_s3
    upload_template unless template_uploaded?
    clear_previous_results_from_s3
    save_final_markup
    write_javascript_models
    upload_to_s3
    delete_tmp_files_for_this_test
  end

  def s3_screenshot(method)
    create_current_test  #TODO: before-filter??
    @@step = @@step+=1
    image_name = "#{@@step}-#{method}" 
    local_path = "#{local_test_root}/#{image_name}.png"
    FileUtils.mkdir_p(local_test_root) unless Dir.exists?(local_test_root)
    @browser.screenshot.save(local_path)
    current_test[:screenshots] << { name: image_name, src: "#{public_path_for_this_test}/#{image_name}.png" }
  end
  
  private

  def copy_template_to_temp_dir
    FileUtils.cp_r(static_site_template_path+'/.', local_root)
  end

  def upload_template
    puts '====== UPLOADING TEMPLATE ========='
    upload_directory(static_site_template_path, '')   
  end

  def template_uploaded?
    bucket.object('index.html').exists?
  end

  def upload_to_s3_possible?
    check_for_env_vars
    true
  rescue Reportir::Error
    return false
  end

  def check_for_env_vars
    raise Reportir::Error.new 'Missing ENV AWS_DEFAULT_BUCKET' unless aws_config[:bucket]
    raise Reportir::Error.new 'Missing ENV AWS_SECRET_ACCESS_KEY' unless aws_config[:secret]
    raise Reportir::Error.new 'Missing ENV AWS_ACCESS_KEY_ID' unless aws_config[:key]
    raise Reportir::Error.new 'Missing ENV AWS_DEFAULT_REGION' unless aws_config[:region]
  end

  def aws_config
    {
      bucket: ENV['AWS_DEFAULT_BUCKET'],
      secret: ENV['AWS_SECRET_ACCESS_KEY'],
      key: ENV['AWS_ACCESS_KEY_ID'],
      region: ENV['AWS_DEFAULT_REGION']
    }
  end

  def delete_tmp_files_for_this_test
    FileUtils.rm_rf local_test_root
  end

  def save_final_markup
    s3_screenshot('final')
    path = "#{local_test_root}/final.html"
    File.open(path, 'w') { |f| f.write @browser.html }
    current_test[:add_links] << { name: 'Markup from Last Page', path: "#{public_path_for_this_test}/final.html" }
  end

  def write_javascript_models
    string = %{
      var navigation = #{array_of_test_names.to_json};
      var tests = #{@@tests.to_json};
    }
    File.open(local_model_file_path, "w") { |f| f.write(string) }
  end

  def clear_previous_results_from_s3
    puts "deleting all previous test data from s3"
    ::Aws::S3::Bucket.new(aws_config[:bucket]).delete_objects({
      delete: {
        objects: [{ key: "#{public_path_for_this_test}" }],
        quiet: true
      }
    })
  end

  def upload_to_s3
    puts '====== UPLOADING RESULTS ========='
    bucket.object('js/models.js').upload_file(local_model_file_path)
    puts "Uploading #{local_model_file_path} to /js/models.js"
    upload_directory(local_test_root, public_path_for_this_test)
    puts '====== S3 UPLOAD COMPLETE ========='
    puts 'URL: ' + static_site_url
    puts '==================================='
  end

  def bucket
    @bucket ||= ::Aws::S3::Resource.new.bucket(aws_config[:bucket])
  end

  def upload_directory(local, remote)
    ::S3Uploader.upload_directory(local, aws_config[:bucket], { 
      :destination_dir => remote, 
      :threads => 5, 
      s3_key: aws_config[:key], 
      s3_secret: aws_config[:secret], 
      region: aws_config[:region] })
  end

  def static_site_template_path
    Gem.find_files('reportir')[1] +'/static_site_template'
  end

  def current_test
    @@tests.select{ |test| test[:name] == test_name }.first
  end

  def create_current_test
    if !current_test || current_test.empty? 
      @@tests << { name: test_name, screenshots: [], add_links: [] }
    end
  end

  def array_of_test_names
    @@tests.map{|t| t[:name] }
  end

  def local_model_file_path
    "#{local_root}/js/models.js"
  end

  def local_test_root
    "#{local_root}/#{public_path_for_this_test}"
  end

  def local_root
    "./tmp/reportir"
  end

  def public_path_for_this_test
    "#{public_artifact_root}/#{test_name}"
  end

  def public_artifact_root
    "test_artifacts"
  end

  def test_name
    ::RSpec.current_example.metadata[:test_name] || ::RSpec.current_example.metadata[:full_description].gsub(/[^\w\s]/,'').gsub(/\s/,'_')
  end

  def static_site_url
    # TODO: use aws-sdk for this.
    "http://#{aws_config[:bucket]}.s3-website-#{aws_config[:region]}.amazonaws.com"
  end

  class Error < ::StandardError; end
end
