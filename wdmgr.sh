#!/bin/bash

wdmgr_dir="$HOME/.wdmgr"

# Функция для сохранения текущей директории
save_directory() {
  read -p "Введите имя для сохранения (по умолчанию 'unnamed'): " name
  name=${name:-unnamed}
  mkdir -p "$wdmgr_dir" && pwd > "$wdmgr_dir/$name"
  echo "Текущая директория сохранена как '$name'"
}

# Функция для вывода нумерованного списка директорий
list_directories() {
  names=()
  contents=()
  maxlen=0

  if [ -d "$wdmgr_dir" ]; then
    for file in "$wdmgr_dir"/*; do
      name=$(basename "$file")
      len=${#name}
      names+=("$name")
      contents+=("$(< "$file")")
      if [ $len -gt $maxlen ]; then
        maxlen=$len
      fi
    done
  fi

  echo "Список сохранённых директорий:"
  if (( ${#names[@]} )); then
    for i in ${!names[@]}; do
      printf "%2d) %${maxlen}s %s\n" "$((i+1))" "${names[$i]}" "${contents[$i]}"
    done
  else
    echo "(Пусто)"
  fi
}

# Функция для выбора директории по номеру
select_directory() {
  list_directories
  if [ -d "$wdmgr_dir" ] && [ -n "$(ls -A "$wdmgr_dir")" ]; then
    read -p "Введите номер директории для выбора: " num
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#names[@]} ]; then
      selected_name="${names[$((num-1))]}"
      selected_path="${contents[$((num-1))]}"
      echo "$1 '$selected_name': $selected_path"
      return 0
    else
      echo "Ошибка: неверный номер"
      return 1
    fi
  else
    echo "Нет сохранённых директорий"
    return 1
  fi
}

# Функция для перехода к сохранённой директории
change_directory() {
  if select_directory "Переход в директорию"; then
    cd "$selected_path" && echo "Теперь вы в: $selected_path" || echo "Ошибка перехода в директорию"
  fi
}

# Функция для просмотра сохранённой директории
show_directory() {
  if select_directory "Просмотр директории"; then
    echo "Путь: $selected_path"
  fi
}

# Функция для удаления сохранённой директории
remove_directory() {
  if select_directory "Удаление директории"; then
    read -p "Вы уверены, что хотите удалить '$selected_name'? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      rm "$wdmgr_dir/$selected_name" && echo "Директория '$selected_name' удалена" || echo "Ошибка удаления"
    else
      echo "Удаление отменено"
    fi
  fi
}

# Функция для удаления всех сохранённых директорий
remove_all_directories() {
  if [ -d "$wdmgr_dir" ] && [ -n "$(ls -A "$wdmgr_dir")" ]; then
    list_directories
    read -p "Вы уверены, что хотите удалить ВСЕ сохранённые директории? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      rm -fr "$wdmgr_dir" && echo "Все директории удалены" || echo "Ошибка удаления"
    else
      echo "Удаление отменено"
    fi
  else
    echo "Нет сохранённых директорий для удаления"
  fi
}

# Главное меню
while true; do
  echo ""
  echo "Меню управления директориями:"
  echo "1) Сохранить текущую директорию"
  echo "2) Перейти к сохранённой директории"
  echo "3) Показать сохранённую директорию"
  echo "4) Удалить сохранённую директорию"
  echo "5) Удалить все сохранённые директории"
  echo "6) Показать список сохранённых директорий"
  echo "0) Выход"
  echo ""

  read -p "Выберите действие (0-6): " choice
  case $choice in
    1) save_directory ;;
    2) change_directory ;;
    3) show_directory ;;
    4) remove_directory ;;
    5) remove_all_directories ;;
    6) list_directories ;;
    0) break ;;
    *) echo "Неверный выбор. Пожалуйста, введите число от 0 до 6." ;;
  esac
done

echo "Работа завершена. До свидания!"
