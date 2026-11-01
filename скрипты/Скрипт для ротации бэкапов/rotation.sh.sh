#!/bin/bash

#папка бэкапов медиавики
BACKUP_MEDIAWIKI_CONTENT_DIR="/home/backupuser/wiki_content"
#папка бэкапов базы данных
BACKUP_DATA_BASE_DIR="/home/backupuser/data_base_backup"
#давность бэкапа в ДНЯХ
TIME=10
#задаем расширение файлов
extension_for_medai_wiki_content_backup="*.tar.gz"

extension_for_data_base_backup="*.backup"


#функция ротации
make_rotation(){
    local path="$1"
    local days="$2"
    local extension="$3"
    echo "Ротация: $path, маска '$extension', старше $days дней"
    find "$path" -maxdepth 1 -type f -name "$extension" -mtime +"$days" -print -delete
}

#НАЧАЛО РАБОТЫ КОДА
#ротация фбэкапов папки медиавики
make_rotation "$BACKUP_MEDIAWIKI_CONTENT_DIR" "$TIME" "$extension_for_medai_wiki_content_backup"
#ротация бэкапов базы данных
make_rotation "$BACKUP_DATA_BASE_DIR" "$TIME" "$extension_for_data_base_backup"
