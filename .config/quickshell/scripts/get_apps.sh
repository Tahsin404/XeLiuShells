#!/bin/bash
# Scrapes system desktop files and caches them as TSV: Name \t Icon \t ExecCommand \t SearchTags
CACHE_FILE="$HOME/.cache/quickshell_apps.tsv"

if [ ! -f "$CACHE_FILE" ]; then
  >"$CACHE_FILE"

  find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | while read -r file; do
    # Skip apps meant to be hidden
    nodisplay=$(grep -im 1 "^NoDisplay=true" "$file")
    if [ -n "$nodisplay" ]; then continue; fi

    name=$(grep -m 1 "^Name=" "$file" | cut -d'=' -f2)
    exec_cmd=$(grep -m 1 "^Exec=" "$file" | cut -d'=' -f2 | sed 's/ %[a-zA-Z]//g')

    # NEW: Extract the intelligent search tags that Wofi uses
    keywords=$(grep -m 1 "^Keywords=" "$file" | cut -d'=' -f2 | tr ';' ' ' | tr '[:upper:]' '[:lower:]')
    categories=$(grep -m 1 "^Categories=" "$file" | cut -d'=' -f2 | tr ';' ' ' | tr '[:upper:]' '[:lower:]')
    generic=$(grep -m 1 "^GenericName=" "$file" | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]')

    search_tags="${keywords} ${categories} ${generic}"

    if [ -n "$name" ] && [ -n "$exec_cmd" ]; then
      icon=""
      name_lower=${name,,}
      if [[ $name_lower == *"browser"* ]] || [[ $name_lower == *"firefox"* ]] || [[ $name_lower == *"chrome"* ]] || [[ $name_lower == *"zen"* ]]; then
        icon=""
      elif [[ $name_lower == *"spotify"* ]]; then
        icon=""
      elif [[ $name_lower == *"discord"* ]] || [[ $name_lower == *"telegram"* ]]; then
        icon=""
      elif [[ $name_lower == *"steam"* ]] || [[ $name_lower == *"game"* ]] || [[ $name_lower == *"heroic"* ]]; then
        icon=""
      elif [[ $name_lower == *"terminal"* ]] || [[ $name_lower == *"kitty"* ]] || [[ $name_lower == *"alacritty"* ]]; then
        icon=""
      elif [[ $name_lower == *"mail"* ]]; then
        icon=""
      elif [[ $name_lower == *"file"* ]] || [[ $name_lower == *"dolphin"* ]] || [[ $name_lower == *"thunar"* ]]; then
        icon=""
      elif [[ $name_lower == *"code"* ]] || [[ $name_lower == *"vim"* ]]; then
        icon=""
      fi

      # Passes the tags as the 4th tab-separated value
      echo -e "${name}\t${icon}\t${exec_cmd}\t${search_tags}" >>"$CACHE_FILE"
    fi
  done

  sort -u -t$'\t' -k1,1 "$CACHE_FILE" -o "$CACHE_FILE"
fi

cat "$CACHE_FILE"
