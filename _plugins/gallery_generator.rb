require "fileutils"
require "digest"

module Jekyll
  class GG < Generator
    safe true
    priority :low

    # Статическая переменная для отслеживания выполнения
    @@generated = false

    def generate(site)
      # Проверяем, был ли генератор уже выполнен
      if @@generated
        Jekyll.logger.info "GG:", "генерация уже выполнена, пропускаем"
        return
      end

      # Путь к папке с изображениями
      img_dir = File.join("docs", "02m")
      output_file = File.join(img_dir, "00gal", "index.md")
      gallery_img_dir = File.join(img_dir, "00gal", "img")

      # Логируем пути для отладки
      Jekyll.logger.info "GG:", "site.source: #{site.source}"
      Jekyll.logger.info "GG:", "img_dir: #{img_dir}"
      Jekyll.logger.info "GG:", "gallery_img_dir: #{gallery_img_dir}"

      # Проверяем существование директории
      unless Dir.exist?(img_dir)
        Jekyll.logger.error "GG:", "директория '#{img_dir}' не найдена"
        return
      end

      # Создаём целевую папку img, но не очищаем её полностью.
      FileUtils.mkdir_p(gallery_img_dir)

      header = <<~HEREDOC
      ---
      title: gallery
      parent: modules
      nav_order: 0
      ---
      HEREDOC

      # Создаём структуру каталогов из docs/02m, исключая 00gal
      Dir.glob(File.join(img_dir, "**", "*")).sort.each do |path|
        next unless File.directory?(path)
        next if path == File.join(img_dir, "00gal")
        next if path.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR)

        rel_dir = path.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
        FileUtils.mkdir_p(File.join(gallery_img_dir, rel_dir))
      end

      # Собираем каталоги с 001.png и 002.jpg, пропуская 00gal
      folder_dirs = Dir.glob(File.join(img_dir, "**", "*")).select do |path|
        File.directory?(path) &&
          path != File.join(img_dir, "00gal") &&
          !path.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR)
      end.sort

      rows = folder_dirs.map do |dir|
        png = File.join(dir, "001.png")
        jpg = File.join(dir, "002.jpg")
        has_png = File.exist?(png)
        has_jpg = File.exist?(jpg)
        next unless has_png || has_jpg
        [dir, png, jpg]
      end.compact

      if rows.empty?
        Jekyll.logger.warn "GG:", "не найдено ни одного каталога с 001.png или 002.jpg в #{img_dir}"
        return
      end

      expected_targets = []
      seen_hashes = {}
      File.open(output_file, "w:utf-8") do |f|
        f.puts header
        f.puts
        f.puts %Q(<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; width: 100%; box-sizing: border-box; margin: 20px 0;">)

        cell_index = 1
        rows.each do |dir, png, jpg|
          row_imgs = [png, jpg].select { |img| File.exist?(img) }
          row_hashes = row_imgs.map { |img| Digest::SHA1.file(img).hexdigest }
          duplicate = row_hashes.any? { |h| seen_hashes.include?(h) }

          if duplicate
            Jekyll.logger.info "GG:", "строка #{dir} пропущена, потому что один из файлов дублирует предыдущий"
            cell_index += 2
            next
          end

          row_imgs.each do |img|
            file_hash = Digest::SHA1.file(img).hexdigest
            seen_hashes[file_hash] = img
          end

          [png, jpg].each do |img|
            if File.exist?(img)
              rel_src = img.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
              expected_targets << rel_src
              destination_path = File.join(gallery_img_dir, rel_src)
              FileUtils.mkdir_p(File.dirname(destination_path))

              if !File.exist?(destination_path) || Digest::SHA1.file(img).hexdigest != Digest::SHA1.file(destination_path).hexdigest
                FileUtils.cp(img, destination_path)
                file_size = File.size(img)
                Jekyll.logger.info "GG:", "скопирован #{img} в #{destination_path} (размер #{file_size} байт)"
              else
                Jekyll.logger.info "GG:", "пропущен #{img}, уже синхронизирован"
              end

              rel_path = "./" + File.join("img", rel_src).tr(File::SEPARATOR, "/")
              rel_dir = File.dirname(rel_src)
              rel_dir = File.dirname(rel_dir) if File.basename(rel_dir) == "img"
              folder_link = rel_dir == "." ? "../" : "../#{rel_dir.tr(File::SEPARATOR, "/")}/"
              Jekyll.logger.info "GG:", "img: #{img}, rel_path: #{rel_path}, folder_link: #{folder_link}"

              f.puts "  <!-- Ячейка #{cell_index} -->"
              f.puts %Q(  <div style="display: flex; justify-content: center; align-items: center; background: #f9f9f9; padding: 10px; min-height: 250px;">)
              f.puts %Q(    <a href="#{folder_link}"><img src="#{rel_path}" alt="" style="max-width: 100%; max-height: 250px; width: auto; height: auto; object-fit: contain;"></a>)
              f.puts "  </div>"
            else
              f.puts %Q(  <div style="display: flex; justify-content: center; align-items: center; background: #f9f9f9; padding: 10px; min-height: 250px;"></div>)
            end
            cell_index += 1
          end
        end

        f.puts "</div>"
      end

      Dir.glob(File.join(gallery_img_dir, "**", "*")).each do |target_path|
        next unless File.file?(target_path)
        rel_target = target_path.sub(/^#{Regexp.escape(gallery_img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
        unless expected_targets.include?(rel_target)
          File.delete(target_path)
          Jekyll.logger.info "GG:", "удалён устаревший файл #{target_path}"
        end
      end

      Dir.glob(File.join(gallery_img_dir, "**", "*")).sort.reverse.each do |path|
        if File.directory?(path) && Dir.empty?(path)
          Dir.rmdir(path)
        end
      end

      @@generated = true
      total_images = rows.size * 2
      Jekyll.logger.info "GG:", "создан #{output_file} (#{total_images} ячеек, #{rows.size} строк)"
    end
  end
end