#!/bin/bash

wdmgr_dir="$HOME/.wdmgr"
groups_dir="$wdmgr_dir/groups"

# Создаем необходимые директории
mkdir -p "$groups_dir"

# Функция для проверки Git репозитория и выполнения команд
check_and_update_git() {
  # Проверяем, является ли директория Git репозиторием
  if [ -d ".git" ]; then
    echo "Обнаружен Git репозиторий в $(pwd)"
    echo "Выполняю git pull..."
    
    # Выполняем git pull
    if git pull; then
      echo "git pull выполнен успешно"
      
      # Показываем статус
      echo "Статус репозитория:"
      git status
    else
      echo "Ошибка при выполнении git pull"
    fi
    
  else
    echo "Директория не является Git репозиторием"
  fi
}

# Функция для получения списка групп с фиксированной нумерацией
get_groups_list() {
  local groups=()
  if [ -d "$groups_dir" ]; then
    # Сортируем по времени создания для фиксированной нумерации
    for file in $(ls -1tr "$groups_dir"/* 2>/dev/null); do
      if [ -f "$file" ]; then
        groups+=("$(basename "$file")")
      fi
    done
  fi
  echo "${groups[@]}"
}

# Функция для проверки наличия групп
has_groups() {
  local groups=($(get_groups_list))
  [ ${#groups[@]} -gt 0 ]
}

# Функция для создания группы при первом запуске
create_first_group() {
  echo "Нет созданных групп."
  read -p "Хотите создать новую группу? (y/n): " confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    create_group
    return 0
  else
    echo "Создание группы отменено."
    return 1
  fi
}

# Функция для вывода нумерованного списка групп
list_groups() {
  local groups=($(get_groups_list))
  local maxlen=0

  echo "Список групп:"
  if (( ${#groups[@]} )); then
    for i in ${!groups[@]}; do
      len=${#groups[$i]}
      if [ $len -gt $maxlen ]; then
        maxlen=$len
      fi
    done
    
    for i in ${!groups[@]}; do
      printf "%2d) %${maxlen}s\n" "$((i+1))" "${groups[$i]}"
    done
  else
    echo "(Пусто)"
  fi
}

# Функция для выбора группы по номеру
select_group() {
  local groups=($(get_groups_list))
  
  while true; do
    echo "Список групп:"
    if (( ${#groups[@]} )); then
      for i in ${!groups[@]}; do
        printf "%2d) %s\n" "$((i+1))" "${groups[$i]}"
      done
      echo " 0) Вернуться в главное меню"
      
      read -p "Введите номер группы для $1: " num
      
      if [ "$num" -eq 0 ]; then
        echo "Возврат в главное меню..."
        return 2
      fi
      
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#groups[@]} ]; then
        selected_group="${groups[$((num-1))]}"
        echo "Выбрана группа: $selected_group"
        return 0
      else
        echo "Ошибка: неверный номер"
      fi
    else
      echo "Нет созданных групп"
      read -p "Нажмите Enter для возврата в главное меню..."
      return 2
    fi
  done
}

# Функция для получения списка директорий в группе с фиксированной нумерацией
get_directories_in_group() {
  local group="$1"
  local group_file="$groups_dir/$group"
  
  local paths=()
  if [ -f "$group_file" ]; then
    # Читаем пути в порядке добавления
    while IFS= read -r path || [ -n "$path" ]; do
      if [ -n "$path" ]; then
        paths+=("$path")
      fi
    done < "$group_file"
  fi
  echo "${paths[@]}"
}

# Функция для вывода нумерованного списка директорий в группе
list_directories_in_group() {
  local group="$1"
  local paths=($(get_directories_in_group "$group"))
  local maxlen=0

  echo "Список директорий в группе '$group':"
  if (( ${#paths[@]} )); then
    for i in ${!paths[@]}; do
      len=${#paths[$i]}
      if [ $len -gt $maxlen ]; then
        maxlen=$len
      fi
    done
    
    for i in ${!paths[@]}; do
      printf "%2d) %s\n" "$((i+1))" "${paths[$i]}"
    done
  else
    echo "(Пусто)"
  fi
}

# Функция для выбора директории в группе по номеру
select_directory_in_group() {
  local group="$1"
  local paths=($(get_directories_in_group "$group"))

  while true; do
    list_directories_in_group "$group"
    if (( ${#paths[@]} )); then
      echo " 0) Вернуться к выбору группы"
      read -p "Введите номер директории для выбора: " num
      
      if [ "$num" -eq 0 ]; then
        echo "Возврат к выбору группы..."
        return 2
      fi
      
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#paths[@]} ]; then
        selected_path="${paths[$((num-1))]}"
        echo "Выбран путь: $selected_path"
        return 0
      else
        echo "Ошибка: неверный номер"
      fi
    else
      echo "Нет сохранённых директорий в группе '$group'"
      read -p "Нажмите Enter для возврата к выбору группы..."
      return 2
    fi
  done
}

# Функция для создания новой группы
create_group() {
  read -p "Введите имя для новой группы: " group_name
  if [ -z "$group_name" ]; then
    echo "Имя группы не может быть пустым"
    return 1
  fi
  
  group_file="$groups_dir/$group_name"
  if [ -f "$group_file" ]; then
    echo "Группа '$group_name' уже существует"
    return 1
  fi
  
  touch "$group_file"
  echo "Группа '$group_name' создана"
  return 0
}

# Функция для переименования группы
rename_group() {
  if select_group "переименования"; then
    read -p "Введите новое имя для группы '$selected_group': " new_name
    if [ -z "$new_name" ]; then
      echo "Имя группы не может быть пустым"
      return 1
    fi
    
    if [ -f "$groups_dir/$new_name" ]; then
      echo "Группа '$new_name' уже существует"
      return 1
    fi
    
    mv "$groups_dir/$selected_group" "$groups_dir/$new_name"
    echo "Группа '$selected_group' переименована в '$new_name'"
  fi
}

# Функция для сохранения текущей директории в группе
save_directory() {
  if ! has_groups; then
    if ! create_first_group; then
      return 1
    fi
    # После создания группы автоматически выбираем её
    local groups=($(get_groups_list))
    selected_group="${groups[0]}"
  else
    if select_group "сохранения директории"; then
      : # Группа выбрана
    else
      return 1
    fi
  fi
  
  group_file="$groups_dir/$selected_group"
  current_path=$(pwd)
  
  # Проверяем, существует ли уже такой путь в группе
  if grep -Fxq "$current_path" "$group_file" 2>/dev/null; then
    echo "Директория уже существует в группе '$selected_group'"
    return 1
  fi
  
  echo "$current_path" >> "$group_file"
  echo "Текущая директория сохранена в группе '$selected_group'"
}

# Функция для перехода к сохранённой директории
change_directory() {
  if ! has_groups; then
    if ! create_first_group; then
      return 2
    fi
  fi

  if select_group "перехода к директории"; then
    if select_directory_in_group "$selected_group"; then
      # Пытаемся перейти в директорию
      if cd "$selected_path"; then
        echo "Теперь вы в: $selected_path"
        check_and_update_git
        return 0
      else
        echo "Ошибка перехода в директорию: $selected_path"
        return 1
      fi
    else
      return $?
    fi
  else
    return 2
  fi
}

# Функция для просмотра сохранённой директории
show_directory() {
  if ! has_groups; then
    if ! create_first_group; then
      return 1
    fi
  fi

  if select_group "просмотра директории"; then
    if select_directory_in_group "$selected_group"; then
      echo "Путь: $selected_path"
      
      # Проверяем наличие Git репозитория
      if [ -d "$selected_path/.git" ]; then
        echo "✓ Это Git репозиторий"
      else
        echo "✗ Это не Git репозиторий"
      fi
    fi
  fi
}

# Функция для удаления сохранённой директории
remove_directory() {
  if ! has_groups; then
    echo "Нет групп для удаления директорий"
    return 1
  fi

  if select_group "удаления директории"; then
    if select_directory_in_group "$selected_group"; then
      read -p "Вы уверены, что хотите удалить директорию из группы '$selected_group'? (y/n): " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        group_file="$groups_dir/$selected_group"
        # Создаем временный файл без удаляемой директории
        grep -vFx "$selected_path" "$group_file" > "$group_file.tmp" && mv "$group_file.tmp" "$group_file"
        echo "Директория удалена из группы '$selected_group'"
      else
        echo "Удаление отменено"
      fi
    fi
  fi
}

# Функция для удаления группы
remove_group() {
  if ! has_groups; then
    echo "Нет групп для удаления"
    return 1
  fi

  if select_group "удаления"; then
    read -p "Вы уверены, что хотите удалить группу '$selected_group'? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      rm "$groups_dir/$selected_group" && echo "Группа '$selected_group' удалена" || echo "Ошибка удаления"
    else
      echo "Удаление отменено"
    fi
  fi
}

# Функция для удаления всех групп
remove_all_groups() {
  local groups=($(get_groups_list))
  if (( ${#groups[@]} )); then
    list_groups
    read -p "Вы уверены, что хотите удалить ВСЕ группы? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      rm -f "$groups_dir"/* && echo "Все группы удалены" || echo "Ошибка удаления"
    else
      echo "Удаление отменено"
    fi
  else
    echo "Нет групп для удаления"
  fi
}

# Сразу пытаемся перейти к сохранённой директории
change_directory
result=$?

# Если переход не удался (пользователь вернулся в меню или нет директорий), показываем главное меню
if [ $result -eq 2 ] || [ $result -eq 1 ]; then
  # Главное меню
  while true; do
    echo ""
    echo "Меню управления группами директорий:"
    echo "1) Создать новую группу"
    echo "2) Переименовать группу"
    echo "3) Сохранить текущую директорию в группе"
    echo "4) Перейти к сохранённой директории"
    echo "5) Показать сохранённую директорию"
    echo "6) Удалить сохранённую директорию"
    echo "7) Удалить группу"
    echo "8) Удалить все группы"
    echo "9) Показать список групп"
    echo "0) Выход"
    echo ""

    read -p "Выберите действие (0-9): " choice
    case $choice in
      1) create_group ;;
      2) rename_group ;;
      3) save_directory ;;
      4) change_directory && break ;;
      5) show_directory ;;
      6) remove_directory ;;
      7) remove_group ;;
      8) remove_all_groups ;;
      9) list_groups ;;
      0) break ;;
      *) echo "Неверный выбор. Пожалуйста, введите число от 0 до 9." ;;
    esac
  done
fi

echo "Работа завершена. До свидания!"
