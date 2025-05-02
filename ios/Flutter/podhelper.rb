# Install pods needed for Flutter plugins.
def install_all_flutter_pods(flutter_application_path = nil)
    flutter_application_path ||= File.join(__dir__, '..', '..')
    load File.join(flutter_application_path, '.flutter-plugins-dependencies')
  
    plugin_pods = parse_KV_file(File.join(flutter_application_path, '.flutter-plugins'))
    plugin_pods.each do |name, path|
      symlink = File.join('.symlinks', 'plugins', name)
      FileUtils.mkdir_p(symlink)
      FileUtils.ln_sf(path, symlink)
      pod name, :path => File.join(symlink, 'ios')
    end
  end
  
  def parse_KV_file(file, separator='=')
    map = {}
    File.foreach(file) do |line|
      next if line.strip.empty? || line.start_with?('#')
      key, value = line.strip.split(separator, 2)
      map[key] = value
    end
    map
  end