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

      # Создаём целевую папку img
      FileUtils.mkdir_p(gallery_img_dir)

      # вычисляем папки-исключения: директории, где 001.png совпадает по размеру и SHA1 с целевым файлом
      target_size = 4581
      target_hash = "f2fc2e7d97d36ec8695b8b44ec2e41e49a8c637d"
      skip_dirs = Dir.glob(File.join(img_dir, "**", "001.png")).select do |file|
        next false if file.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR)
        File.size(file) == target_size && Digest::SHA1.file(file).hexdigest == target_hash
      end.map { |f| File.dirname(f) }

      # === ЭТАП 1: Очистка 00gal от устаревших файлов ===
      start_time = Time.now
      Jekyll.logger.info "GG:", "ЭТАП 1: Проверка и удаление устаревших файлов из 00gal"
      cleanup_stale_files(gallery_img_dir, img_dir, skip_dirs)
      cleanup_empty_dirs(gallery_img_dir)
      Jekyll.logger.info "GG:", "ЭТАП 1 выполнен за #{(Time.now - start_time).round(2)}c"

      # === ЭТАП 2: Синхронизация новых файлов в 00gal ===
      start_time = Time.now
      Jekyll.logger.info "GG:", "ЭТАП 2: Синхронизация файлов из 02m в 00gal"
      sync_new_files(gallery_img_dir, img_dir, skip_dirs)
      Jekyll.logger.info "GG:", "ЭТАП 2 выполнен за #{(Time.now - start_time).round(2)}c"

      # === ЭТАП 3: Создание структуры каталогов ===
      start_time = Time.now
        # Создавать только нужные каталоги — это будет сделано позже на основе
        # реального списка папок с изображениями (чтобы не создавать пустые папки).
        Jekyll.logger.info "GG:", "ЭТАП 3: пропущен (директории будут созданы по факту)"

      # === ЭТАП 4: Генерация HTML-галереи ===
      start_time = Time.now
      header = <<~HEREDOC
      ---
      title: gallery
      parent: modules
      nav_order: 0
      ---
      HEREDOC

      # Собираем каталоги с 001.png и 002.jpg, пропуская 00gal и папки-исключения
      folder_dirs = Dir.glob(File.join(img_dir, "**", "*")).select do |path|
        File.directory?(path) &&
          path != File.join(img_dir, "00gal") &&
          !path.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR) &&
          !skip_dirs.any? { |skip_dir| path == skip_dir || path.start_with?(skip_dir + File::SEPARATOR) }
      end.sort

      rows = folder_dirs.map do |dir|
        png = File.join(dir, "001.png")
        jpg = File.join(dir, "002.jpg")
        has_png = File.exist?(png)
        has_jpg = File.exist?(jpg)
        next unless has_png || has_jpg
        [dir, png, jpg]
      end.compact

      # Создаём только те директории в 00gal, которые действительно содержат изображения
      rows.each do |dir, png, jpg|
        rel_dir = dir.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
        FileUtils.mkdir_p(File.join(gallery_img_dir, rel_dir))
      end

      if rows.empty?
        Jekyll.logger.warn "GG:", "не найдено ни одного каталога с 001.png или 002.jpg в #{img_dir}"
        return
      end

      expected_targets = []
      File.open(output_file, "w:utf-8") do |f|
        f.puts header
        f.puts
        f.puts %Q(<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; width: 100%; box-sizing: border-box; margin: 20px 0;">)

        cell_index = 1
        rows.each do |dir, png, jpg|
          [png, jpg].each do |img|
            if File.exist?(img)
              rel_src = img.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
              expected_targets << rel_src

              rel_path = "./" + File.join("img", rel_src).tr(File::SEPARATOR, "/")
              rel_dir = File.dirname(rel_src)
              rel_dir = File.dirname(rel_dir) if File.basename(rel_dir) == "img"
              folder_link = rel_dir == "." ? "../" : "../#{rel_dir.tr(File::SEPARATOR, "/")}/"

              f.puts "  <!-- Ячейка #{cell_index} -->"
              f.puts %Q(  <div style="display: flex; justify-content: center; align-items: center; background: #ffffff; padding: 10px; min-height: 250px;">)
              f.puts %Q(    <a href="#{folder_link}"><img src="#{rel_path}" alt="" style="max-width: 100%; max-height: 250px; width: auto; height: auto; object-fit: contain;"></a>)
              f.puts "  </div>"
            else
              f.puts %Q(  <div style="display: flex; justify-content: center; align-items: center; background: #ffffff; padding: 10px; min-height: 250px;"></div>)
            end
            cell_index += 1
          end
        end

        f.puts "</div>"
      end
      Jekyll.logger.info "GG:", "ЭТАП 4 выполнен за #{(Time.now - start_time).round(2)}c"

      @@generated = true
      total_images = rows.size * 2
      Jekyll.logger.info "GG:", "создан #{output_file} (#{total_images} ячеек, #{rows.size} строк)"
    end

    private

    # ЭТАП 1: Удалить из 00gal папки, соответствующие директориям с 001.png в 02m
    def cleanup_stale_files(gallery_img_dir, img_dir, skip_dirs)
      deleted_count = 0

      skip_dirs.each do |src_dir|
        rel_dir = src_dir.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")
        gal_dir = File.join(gallery_img_dir, rel_dir)
        if Dir.exist?(gal_dir)
          FileUtils.rm_rf(gal_dir)
          Jekyll.logger.info "GG:", "ЭТАП 1: удалена папка #{gal_dir} (встречен 001.png в исходной папке)"
          deleted_count += 1
        end
      end

      Dir.glob(File.join(gallery_img_dir, "**", "*")).each do |gal_file|
        next unless File.file?(gal_file)

        # Путь файла внутри 00gal/img
        rel_path = gal_file.sub(/^#{Regexp.escape(gallery_img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")

        # Ищем соответствующий файл в 02m (исключая 00gal)
        source_file = File.join(img_dir, rel_path)

        # Проверяем, что это не внутри 00gal
        next if source_file.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR)

        # Пропускаем файлы, чьи исходные директории находятся в skip_dirs
        next if skip_dirs.include?(File.dirname(source_file))

        if File.exist?(source_file)
          # Быстрая проверка: сравниваем размер
          gal_size = File.size(gal_file)
          src_size = File.size(source_file)

          if gal_size != src_size
            # Размеры не совпадают - точно удаляем
            File.delete(gal_file)
            Jekyll.logger.info "GG:", "ЭТАП 1: удалён #{gal_file} (размер изменился)"
            deleted_count += 1
          end
          # Если размеры совпадают, считаем что файл актуален (избегаем SHA1)
        else
          # Если источника нет вообще, удалим
          File.delete(gal_file)
          Jekyll.logger.info "GG:", "ЭТАП 1: удалён #{gal_file} (источника не существует)"
          deleted_count += 1
        end
      end
      Jekyll.logger.info "GG:", "ЭТАП 1 завершён: удалено #{deleted_count} файлов" if deleted_count > 0
    end

    def cleanup_empty_dirs(top_dir)
      loop do
        removed = false
        Dir.glob(File.join(top_dir, "**", "*")).sort.reverse.each do |path|
          next unless File.directory?(path)
          next if path == top_dir
          if Dir.children(path).empty?
            Dir.rmdir(path)
            Jekyll.logger.info "GG:", "ЭТАП 1: удалена пустая папка #{path}"
            removed = true
          end
        end
        break unless removed
      end
    end

    # ЭТАП 2: Скопировать файлы из 02m (исключая 00gal) в 00gal если их нет
    def sync_new_files(gallery_img_dir, img_dir, skip_dirs)
      copied_count = 0
      Dir.glob(File.join(img_dir, "**", "{001.png,002.jpg}")).each do |source_file|
        # Пропускаем файлы из 00gal
        next if source_file.start_with?(File.join(img_dir, "00gal") + File::SEPARATOR)

        # Пропускаем файлы из директорий со 001.png
        next if skip_dirs.include?(File.dirname(source_file))

        # Вычисляем путь относительно img_dir
        rel_path = source_file.sub(/^#{Regexp.escape(img_dir)}#{Regexp.escape(File::SEPARATOR)}/, "")

        # Целевой путь в 00gal
        dest_file = File.join(gallery_img_dir, rel_path)

        # Создаём директорию если нужно
        FileUtils.mkdir_p(File.dirname(dest_file))

        if !File.exist?(dest_file)
          # Файл не существует - копируем
          FileUtils.cp(source_file, dest_file)
          file_size = File.size(source_file)
          Jekyll.logger.info "GG:", "ЭТАП 2: скопирован #{source_file} (#{file_size} байт)"
          copied_count += 1
        end
      end
      Jekyll.logger.info "GG:", "ЭТАП 2 завершён: скопировано #{copied_count} файлов" if copied_count > 0
    end
  end
end