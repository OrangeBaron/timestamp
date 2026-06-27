#!/bin/bash

# Stampa il logo
cat << 'EOF'
   ___________.__                 _________ __                         
   \__    ___/|__| _____   ____  /   _____//  |______    _____ ______  
     |    |   |  |/     \_/ __ \ \_____  \\   __\__  \  /     \\____ \ 
     |    |   |  |  Y Y  \  ___/ /        \|  |  / __ \|  Y Y  \  |_> >
     |____|   |__|__|_|  /\___  >_______  /|__| (____  /__|_|  /   __/ 
                       \/     \/        \/           \/      \/|__|    
 _           ___                                  ___        _            
| |__ _  _  | __| _ __ _ _ _  __ ___ ___ __ ___  | __|__  __| |_  ___ _ _ 
| '_ \ || | | _| '_/ _` | ' \/ _/ -_|_-</ _/ _ \ | _/ _ \/ _| ' \/ -_) '_|
|_.__/\_, | |_||_| \__,_|_||_\__\___/__/\__\___/ |_|\___/\__|_||_\___|_|  
      |__/                                                                
EOF

echo "" # Riga vuota

# --- SELEZIONE DELLA CARTELLA ---
# Controlla se è stato passato un percorso come argomento
if [ -n "$1" ]; then
    FOLDER_PATH="$1"
    echo "Percorso ricevuto da riga di comando: $FOLDER_PATH"
else
    # Se non c'è alcun argomento, usa la modalità interattiva
    echo "Trascina qui la cartella da processare e premi Invio:"
    read -r FOLDER_PATH
fi

# --- PULIZIA DEL PERCORSO ---
FOLDER_PATH="${FOLDER_PATH%"${FOLDER_PATH##*[![:space:]]}"}"
FOLDER_PATH="${FOLDER_PATH#\'}"
FOLDER_PATH="${FOLDER_PATH%\'}"
FOLDER_PATH="${FOLDER_PATH//\\ / }"

# Verifica che esista
if [ ! -d "$FOLDER_PATH" ]; then
    echo "Errore: Il percorso inserito non è valido o non è una cartella."
    exit 1
fi

echo ""
echo "Calcolo delle cartelle in corso, un attimo di pazienza..."

# Conta numero totale di cartelle
TOTAL_DIRS=$(find "$FOLDER_PATH" -type d | wc -l | tr -d ' ')

if [ "$TOTAL_DIRS" -eq 0 ]; then
    echo "Nessuna cartella trovata."
    exit 0
fi

echo "Elaborazione in corso su: $FOLDER_PATH"
echo "Cartelle totali da processare: $TOTAL_DIRS"
echo ""

# Inizializza contatore e file temporaneo per gli errori
COUNT=0
ERROR_LOG=$(mktemp /tmp/timestamp_errors.XXXXXX)

# Elabora in modalità bottom-up
find "$FOLDER_PATH" -depth -type d | while read -r dir; do
    
    # Dirottiamo anche gli eventuali errori di 'ls' nel log
    newest=$(ls -tA "$dir" 2>>"$ERROR_LOG" | grep -v '^\.DS_Store$' | head -n 1)

    if [ -n "$newest" ]; then
        # Dirottiamo gli errori di 'touch' aggiungendo 2>>"$ERROR_LOG"
        touch -r "$dir/$newest" "$dir" 2>>"$ERROR_LOG"
    fi

    # --- PROGRESS BAR ---
    ((COUNT++))
    PERCENT=$(( COUNT * 100 / TOTAL_DIRS ))
    
    # Barra lunga al massimo 50 caratteri
    FILLED=$(( PERCENT / 2 ))
    EMPTY=$(( 50 - FILLED ))
    
    # Costruisce la barra
    BAR=$(printf "%${FILLED}s" | tr ' ' '█')
    SPACE=$(printf "%${EMPTY}s" | tr ' ' '░')
    
    # Stampa la barra
    printf "\rProgresso: [%s%s] %d%% (%d/%d)" "$BAR" "$SPACE" "$PERCENT" "$COUNT" "$TOTAL_DIRS"
    
done

# Spazio per non sovrascrivere la barra
echo ""
echo ""
echo "Completato! Le date di modifica sono state aggiornate con successo."

# --- GESTIONE ERRORI ---
# Se il file non è vuoto lo stampa
if [ -s "$ERROR_LOG" ]; then
    echo ""
    echo "⚠️ Durante l'elaborazione si sono verificati i seguenti errori:"
    cat "$ERROR_LOG"
fi

# Elimina file temporaneo
rm -f "$ERROR_LOG"