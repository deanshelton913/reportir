require "reportir/version"
require 's3_uploader'
require 'aws-sdk'

module Reportir
  @@static_site_template_path = Gem.find_files('reportir')[1] +'/static_site_template'
  @@template_subdirectory_for_test_artifacts = 'test_run'
  @@step = 0

  def upload_result_to_s3_as_static_site
    check_for_env_vars
    clone_template
    reset_orig_template # TODO: clone before screenshots are possible
    save_final_markup_in_clone
    write_ractive_models_in_clone(screenshots: screenshot_paths, nav: nav_links)
    upload_clone_to_s3
    delete_local_clone
  end
  
  private

  def check_for_env_vars
    raise Reportir::Error.new 'Missing ENV AWS_DEFAULT_BUCKET' unless ENV['AWS_DEFAULT_BUCKET']
    raise Reportir::Error.new 'Missing ENV AWS_SECRET_ACCESS_KEY' unless ENV['AWS_SECRET_ACCESS_KEY']
    raise Reportir::Error.new 'Missing ENV AWS_ACCESS_KEY_ID' unless ENV['AWS_ACCESS_KEY_ID']
    raise Reportir::Error.new 'Missing ENV AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION']
  end

  def clone_template
    FileUtils.cp_r "#{@@static_site_template_path}/.", clone_dir_path
  end

  def reset_orig_template
    FileUtils.rm_rf "#{@@static_site_template_path}/#{@@template_subdirectory_for_test_artifacts}"
  end

  def save_final_markup_in_clone
    s3_screenshot('final')
    File.open("#{deletable_data_path}/final.html", 'w') {|f| f.write @browser.html }
  end

  def write_ractive_models_in_clone(data)
    data.each do |k,v|
      model = {el: "##{k}_container", template: "##{k}_template", data: {k => v}}
      File.open("#{clone_dir_path}/js/main.js", "a") { |f| f.write("var #{k} = new Ractive(#{model.to_json});\n") }
    end
  end

  def upload_clone_to_s3
    puts '====== STARTING S3 UPLOAD ========='
    puts ''
    ::Aws::S3::Bucket.new(ENV['AWS_DEFAULT_BUCKET']).clear!
    ::S3Uploader.upload_directory(clone_dir_path, ENV['AWS_DEFAULT_BUCKET'], { 
      :destination_dir => test_name, 
      :threads => 5, 
      s3_key: ENV['AWS_ACCESS_KEY_ID'], 
      s3_secret: ENV['AWS_SECRET_ACCESS_KEY'], 
      region: ENV['AWS_DEFAULT_REGION'] })   
    puts ''
    puts '====== S3 UPLOAD COMPLETE ========='
    puts 'URL: ' + static_site_url
    puts '==================================='
  end

  def delete_local_clone
    FileUtils.rm_rf clone_dir_path
  end

  def test_name
    RSpec.current_example.metadata[:full_description].gsub(/[^\w\s]/,'').gsub(/\s/,'_')
  end

  def clone_dir_path
    "./tmp/#{test_name}"
  end

  def static_site_url
    "http://#{ENV['AWS_DEFAULT_BUCKET']}.s3-website-#{ENV['AWS_DEFAULT_REGION']}.amazonaws.com/#{test_name}"
  end

  def s3_screenshot(method)
    @@step = @@step+=1
    image_name = "#{@@step}-#{method}" 
    FileUtils.mkdir_p(deletable_data_path) unless Dir.exists?(deletable_data_path)
    @browser.screenshot.save("#{deletable_data_path}/#{image_name}.png")
  end

  def deletable_data_path
    "#{clone_dir_path}/#{@@template_subdirectory_for_test_artifacts}"
  end

  def nav_links
    {'Last Page as Markup' => "#{@@template_subdirectory_for_test_artifacts}/final.html"}
  end

  def screenshot_paths
    images = []
    Dir["#{deletable_data_path}/**/*.png"].sort_by { |x| x[/\d+/].to_i }.each do |src|
      images << "#{@@template_subdirectory_for_test_artifacts}/#{Pathname.new(src).basename}"
    end
    images
  end

  def clear_out_any_old_results
    puts "> Cleaning out old #{deletable_data_path} directory"
    FileUtils.rm_rf "#{deletable_data_path}/*"
  end
  class Error < ::StandardError; end
end
