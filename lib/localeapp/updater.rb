require 'fileutils'

module Localeapp
  class Updater

    def update(data)
      data['locales'].each do |short_code|
        filename = File.join(Localeapp.configuration.translation_data_directory, "#{short_code}.yml")

        if File.exist?(filename)
          translations = YAML.load(File.read(filename))
          if data['translations'] && data['translations'][short_code]
            new_data = { short_code => data['translations'][short_code] }
            translations.deep_merge!(new_data)
          end
        else
          translations = { short_code => data['translations'][short_code] }
        end

        if data['deleted']
          data['deleted'].each do |key|
            remove_flattened_key!(translations, short_code, key)
          end
        end

        if translations[short_code]
          atomic_write(filename) do |file|
            file.write translations.ya2yaml[5..-1]
          end
        end
      end
    end

    private
    def remove_flattened_key!(hash, locale, key)
      keys = I18n.normalize_keys(locale, key, '').map(&:to_s)
      current_key = keys.shift
      remove_child_keys!(hash[current_key], keys)
      hash
    end

    def remove_child_keys!(sub_hash, keys)
      return if sub_hash.nil?
      current_key = keys.shift
      if keys.empty?
        sub_hash.delete(current_key)
      else
        child_hash = sub_hash[current_key]
        unless child_hash.nil?
          remove_child_keys!(child_hash, keys)
          if child_hash.empty?
            sub_hash.delete(current_key)
          end
        end
      end
    end

    # originally from ActiveSupport
    def atomic_write(file_name, temp_dir = Dir.tmpdir)
      temp_file = Tempfile.new(File.basename(file_name), temp_dir)
      yield temp_file
      temp_file.close
      # heroku has /tmp on a different fs
      # so move first to sure they're on the same fs
      # so rename will work
      FileUtils.mv(temp_file.path, "#{file_name}.tmp")
      File.rename("#{file_name}.tmp", file_name)
    end
  end
end
