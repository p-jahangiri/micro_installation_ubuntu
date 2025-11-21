#!/bin/bash

# Set variables for whiptail dimensions
TITLE="Consul Setting Menu"
HEIGHT=15
WIDTH=60
CHOICE_HEIGHT=6

should_exit=0

while [ $should_exit -eq 0 ]
do
    # Create the whiptail menu
    CHOICE=$(whiptail --clear \
                --backtitle "System Management Tool" \
                --title "$TITLE" \
                --menu "Please select an option:" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "1" "Run added new configuration" \
                "2" "Run update json file " \
                "3" "Run update key/value in consul" \
                "4" "Back to installation" \
                "5" "Exit" \
                3>&1 1>&2 2>&3)

    # Check if user pressed Cancel or ESC
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
        whiptail --title "Confirmation" --yesno "Are you sure you want to exit?" 8 40
        if [ $? = 0 ]; then
            should_exit=1
        fi
        continue
    fi

    # Handle the user's choice
    case $CHOICE in
        1)
            whiptail --title "Information" --infobox "Running get-consul-setting.sh..." 8 40
            sleep 1
            if [ -f "get-consul-setting.sh" ]; then
                bash get-consul-setting.sh
                exitcode=$?
                if [ $exitcode -eq 0 ]; then
                    whiptail --title "Success" --msgbox "get-consul-setting.sh completed successfully!" 8 50
                else
                    whiptail --title "Error" --msgbox "get-consul-setting.sh failed with exit code $exitcode" 8 50
                fi
            else
                whiptail --title "Error" --msgbox "File get-consul-setting.sh not found!" 8 40
            fi
            ;;
        2)
            whiptail --title "Information" --infobox "Running update-json.sh..." 8 40
            sleep 1
            if [ -f "update-json.sh" ]; then
                bash update-json.sh
                exitcode=$?
                if [ $exitcode -eq 0 ]; then
                    whiptail --title "Success" --msgbox "update-json.sh completed successfully!" 8 50
                else
                    whiptail --title "Error" --msgbox "update-json.sh failed with exit code $exitcode" 8 50
                fi
            else
                whiptail --title "Error" --msgbox "File update-json.sh not found!" 8 40
            fi
            ;;
        3)
            whiptail --title "Information" --infobox "Running Consul-update.sh..." 8 40
            sleep 1
            if [ -f "Consul-update.sh" ]; then
                bash Consul-update.sh
                exitcode=$?
                if [ $exitcode -eq 0 ]; then
                    whiptail --title "Success" --msgbox "Consul-update.sh completed successfully!" 8 50
                else
                    whiptail --title "Error" --msgbox "Consul-update.sh failed with exit code $exitcode" 8 50
                fi
            else
                whiptail --title "Error" --msgbox "File Consul-update.sh not found!" 8 40
            fi
            ;;
        4)
            whiptail --title "Confirmation" --yesno "Do you want to go back to installation?" 8 45
            if [ $? = 0 ]; then
                if [ -d "/home/micro_installation_ubuntu" ]; then
                    cd /home/micro_installation_ubuntu
                    if [ -f "install.sh" ]; then
                        whiptail --title "Information" --infobox "Switching to installation..." 8 40
                        sleep 1
                        bash install.sh
                    else
                        whiptail --title "Error" --msgbox "install.sh not found in /home/micro_installation_ubuntu!" 8 60
                    fi
                else
                    whiptail --title "Error" --msgbox "Directory /home/micro_installation_ubuntu not found!" 8 60
                fi
            fi
            ;;
        5)
            whiptail --title "Confirmation" --yesno "Are you sure you want to exit?" 8 40
            if [ $? = 0 ]; then
                whiptail --title "Goodbye" --msgbox "Thank you for using the System Management Tool!" 8 50
                should_exit=1
            fi
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid option selected!" 8 40
            ;;
    esac
done

clear
echo "Exiting System Management Tool..."