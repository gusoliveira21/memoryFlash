#!/bin/bash

# Configurar o caminho do Android SDK
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export PATH=$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$PATH

# Configurar o diretório dos AVDs
export ANDROID_AVD_HOME=/Volumes/Desenvolvimento_hub/emulador

# Obter a lista de emuladores disponíveis
AVD_LIST=$(emulator -list-avds)

# Verifica se há emuladores disponíveis
if [ -z "$AVD_LIST" ]; then
    osascript -e 'display notification "Nenhum emulador encontrado!" with title "Erro"'
    exit 1
fi

# Criar a lista formatada para o AppleScript (remove espaços extras e adiciona aspas corretamente)
AVD_LIST_FORMATTED=$(echo "$AVD_LIST" | awk '{printf "\"%s\", ", $0}' | sed 's/, $//')

# Exibir popup de seleção para o usuário
AVD_NAME=$(osascript -e "choose from list {$AVD_LIST_FORMATTED} with prompt \"Escolha um dispositivo para iniciar:\" default items {\"$AVD_LIST\"}")

# Se o usuário cancelar ou não selecionar nada, sair do script
if [ "$AVD_NAME" = "false" ] || [ -z "$AVD_NAME" ]; then
    exit 0
fi

# Limpar a string retornada (AppleScript pode adicionar aspas extras ou um formato inesperado)
AVD_NAME=$(echo "$AVD_NAME" | sed 's/^"\(.*\)"$/\1/')

# Exibir notificação de que o emulador está iniciando
osascript -e "display notification \"Iniciando o emulador: $AVD_NAME...\" with title \"Android Emulator\""

# Executar o emulador
emulator -avd "$AVD_NAME" &

