#!/bin/bash
#имя базы, дамп которой делаем
DB_NAME="my_wiki"
#роль
DB_USER="wikiuser"
#на каком хосте
DB_HOST="localhost"
#путь, где хранятся дампы
BACKUP_DIR="/home/backupuser/data_base_backup"
#путь к файлу дампа + генерация названия
DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_$(date +%Y-%m-%d_%H-%M).backup"
#ip-адрес сервера для хранения бэкапов
IP="192.168.0.100"
NAME="backupuser"

#пароль для базы данных
export PGPASSFILE="/home/backupuser/.pgpass"

#создадим папку ,если вдруг ее нет, чтоб не было ошибки
mkdir -p "$BACKUP_DIR"

#дамп
pg_dump -h "$DB_HOST" -U "$DB_USER" -Fc -f "$DUMP_FILE" "$DB_NAME"
if [ $? -ne 0 ]; then
    echo "Ошибка pg_dump!" >&2
    rm -f "$DUMP_FILE"
    exit 1
fi


# проверка, что дамп читается
if ! pg_restore -l "$DUMP_FILE" > /dev/null 2>&1; then
    echo "Дамп повреждён!" >&2
    rm -f "$DUMP_FILE"
    exit 1
fi

# защита от 0-байтного файла
if [ ! -s "$DUMP_FILE" ]; then
    echo "Дамп пустой!" >&2
    rm -f "$DUMP_FILE"
    exit 1
fi
#вывод в лог
echo "Дамп создан: $DUMP_FILE"


#проверяем доступность сервера хранения бэкапов
if /bin/ping -c4 "$IP" &> /dev/null
then

    #отправялем по scp файл архива. Для этого устанавливаем соединение под специально созданным для этого пользователем 
    #пользователь должен существовать на сервере хранения бэкапов!
    echo "Подготовка к отправке бэкапа"
    scp -i /home/backupuser/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new "$DUMP_FILE" "$NAME@$IP:$BACKUP_DIR"

    #проверяем код выполнения scp и успешность отправки файла
    if [ $? -eq 0 ]; then
        echo "Копирование успешно."
        rm -f "$DUMP_FILE"
        exit 0
    else
        echo "Ошибка при отправке архива на сервер!"
        # Локальный архив не удаляем, чтобы его можно было проверить/отправить вручную
        exit 10
    fi

#если сервер недоступен, то завершаем скрипт
else

    echo "Сервер для резервного копирования недоступен!"

    exit 1

fi
