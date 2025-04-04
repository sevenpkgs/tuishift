#!/usr/bin/env bash

#                       tuishift                       #
#                A script by @sevenpkgs                #

# A TUI controller for Redshift.
# vim keybindings.
#   g: Set temperature by typing it
#   d: Toggle between hardcoded day and night temperature values
#   t: Toggle redshift on/off
#   q: Quit

# Day and Night temp
DAY_TEMP=6500
NIGHT_TEMP=3500
day_mode=1

# General settings
MIN_TEMP=1000         # Minimum temp
MAX_TEMP=10000        # Maximum temp
TEMP=6500             # Starting temp
SLIDER_WIDTH=50       # Width of the slider bar
INCREMENT=500         # Temperature step per key press

redshift_enabled=1

apply_temp() {
    redshift -PO "$TEMP" >/dev/null
}

disable_redshift() {
    redshift -x >/dev/null
}

toggle_redshift() {
    if [ $redshift_enabled -eq 1 ]; then
        disable_redshift
        redshift_enabled=0
    else
        redshift_enabled=1
        apply_temp
    fi
}

GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
YELLOW=$'\033[0;33m'
PURPLE=$'\033[0;35m'
NC=$'\033[0m'

draw_slider() {
    tput cup 0 0

    printf "${CYAN}Redshift TUI Controller${NC}\n"
    printf "${PURPLE}h: Decrease | l: Increase | g: Set Temp | d: Toggle Day/Night | t: Toggle Redshift | q: Quit${NC}\n\n"

    # get marker pos
    pos=$(( (TEMP - MIN_TEMP) * SLIDER_WIDTH / (MAX_TEMP - MIN_TEMP) ))
    slider=""

    # build slider
    for (( i=0; i<SLIDER_WIDTH; i++ )); do
        if [ $i -eq $pos ]; then
            slider+="${GREEN}|${NC}"
        else
            slider+="-"
        fi
    done

    # print the current temp and slider
    printf "Temperature: %sK\n" "$TEMP"
    printf "[%b]\n" "$slider"

    # show redshift state.
    tput cr 
    if [ $redshift_enabled -eq 1 ]; then
        printf "Redshift: ${GREEN}ON${NC}  \n"
    else
        printf "Redshift: ${YELLOW}OFF${NC} \n"
    fi
}

tput civis
clear
stty -echo -icanon time 0 min 0
trap "tput cnorm; stty sane; clear; exit" INT TERM EXIT

# apply temp if redshift is enabled
if [ $redshift_enabled -eq 1 ]; then
    apply_temp
fi

while true; do
    draw_slider

    # read key with short timeout to avoid lag
    read -rsn1 -t 0.05 key

    if [ -n "$key" ]; then
        case "$key" in
            q) break ;;
            t) toggle_redshift ;;
            h)
                TEMP=$(( TEMP - INCREMENT ))
                if [ $TEMP -lt $MIN_TEMP ]; then
                    TEMP=$MIN_TEMP
                fi
                ;;
            l)
                TEMP=$(( TEMP + INCREMENT ))
                if [ $TEMP -gt $MAX_TEMP ]; then
                    TEMP=$MAX_TEMP
                fi
                ;;
            g)
                tput cnorm
                stty sane
                printf "\nEnter temperature (K): "
                read new_temp
                tput cuu1
                tput el
                stty -echo -icanon time 0 min 0
                tput civis
                # validate input and update temp
                if [[ $new_temp =~ ^[0-9]+$ ]]; then
                    TEMP=$new_temp
                    if [ $TEMP -lt $MIN_TEMP ]; then
                        TEMP=$MIN_TEMP
                    elif [ $TEMP -gt $MAX_TEMP ]; then
                        TEMP=$MAX_TEMP
                    fi
                fi
                ;;
            d)
              # toggle between day and night temps
                if [ $day_mode -eq 1 ]; then
                    TEMP=$NIGHT_TEMP
                    day_mode=0
                else
                    TEMP=$DAY_TEMP
                    day_mode=1
                fi
                ;;
        esac

        if [ $redshift_enabled -eq 1 ]; then
            apply_temp
        fi
    fi
done

tput cnorm
stty sane
clear
