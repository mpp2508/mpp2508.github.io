require "fileutils"

module Jekyll
  class GalleryGenerator < Generator
    safe true
    priority :low

    # Статическая переменная для отслеживания выполнения
    @@generated = false

    def generate(site)
      # Проверяем, был ли генератор уже выполнен
      if @@generated
        Jekyll.logger.info "GalleryGenerator:", "генерация уже выполнена, пропускаем"
        return
      end

      # Путь к папке с изображениями
      img_dir = File.join("docs", "02m")
      output_file = File.join(img_dir, "00gal", "index.md")
      gallery_img_dir = File.join(img_dir, "00gal", "img")

      # Логируем пути для отладки
      Jekyll.logger.info "GalleryGenerator:", "site.source: #{site.source}"
      Jekyll.logger.info "GalleryGenerator:", "img_dir: #{img_dir}"
      Jekyll.logger.info "GalleryGenerator:", "gallery_img_dir: #{gallery_img_dir}"

      # Проверяем существование директории
      unless Dir.exist?(img_dir)
        Jekyll.logger.error "GalleryGenerator:", "директория '#{img_dir}' не найдена"
        return
      end

      # Очищаем папку gallery_img_dir перед копированием
      FileUtils.rm_rf(gallery_img_dir) if Dir.exist?(gallery_img_dir)
      FileUtils.mkdir_p(gallery_img_dir)

      header = <<~HEREDOC
      ---
      title: галерея
      parent: модули
      nav_order: 0
      ---
      HEREDOC

      # Собираем изображения
      images = Dir.glob(File.join(img_dir, "**", "001.png")).sort

      # Проверяем, есть ли изображения
      if images.empty?
        Jekyll.logger.warn "GalleryGenerator:", "не найдено ни одного файла 001.png в #{img_dir}"
        return
      end

      File.open(output_file, "w:utf-8") do |f|
        f.puts header
        f.puts
        images.each_with_index do |img, index|
          # Проверяем существование файла
          unless File.exist?(img)
            Jekyll.logger.error "GalleryGenerator:", "файл '#{img}' не найден"
            next
          end

          # Проверяем размер файла (5 КБ = 5120 байт)
          file_size = File.size(img)
          if file_size < 5120
            Jekyll.logger.info "GalleryGenerator:", "файл '#{img}' пропущен (размер #{file_size} байт < 5120 байт)"
            next
          end

          # Формируем уникальное имя файла в папке img/
          new_filename = "img_#{index + 1}_001.png"
          destination_path = File.join(gallery_img_dir, new_filename)

          # Копируем файл в docs/02m/00gal/img/
          FileUtils.cp(img, destination_path)
          Jekyll.logger.info "GalleryGenerator:", "скопирован #{img} в #{destination_path} (размер #{file_size} байт)"

          # Формируем относительный путь для изображения
          rel_path = File.join("img", new_filename)

          # Формируем ссылку на родительскую папку (без /img)
          folder = File.dirname(img.sub(/^#{Regexp.escape(img_dir)}\//, "")).sub(/\/img$/, "")
          folder_link = "../#{folder}/"

          # Логируем пути для отладки
          Jekyll.logger.info "GalleryGenerator:", "img: #{img}, rel_path: #{rel_path}, folder_link: #{folder_link}"

          f.puts "[![](#{rel_path})](#{folder_link})"
        end
      end

      # Устанавливаем флаг, что генерация выполнена
      @@generated = true
      Jekyll.logger.info "GalleryGenerator:", "создан #{output_file} (#{images.size} картинок)"
    end
  end
end