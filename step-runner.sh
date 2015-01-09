#!/bin/bash

#----------------------------------------------------------------------------#
# Step-runner - A smart utility to easily execute batch jobs in steps that
# need user monitoring.
# Copyright (C) 2015  Niklas Rosenqvist

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
#----------------------------------------------------------------------------#

clear
appname="step-runner"
stepsdir="$1"
steps=()
stepnames=()

## Set working directory to pwd if none has been provided
if [ -z "$stepdsir" ]; then
    stepsdir="$(pwd)"
fi

## Make sure that the working directory exists
if [ ! -d "$stepsdir" ]; then
    echo "The specified directory doesn't exist ($stepsdir)."
fi

## Include global vars file if it exists
globalspath="$stepsdir/globals.conf"

if [ -f "$globalspath" ]; then
    source "$globalspath"
fi

##-----------Functions-----------##
function show_heading {
    echo -e "\033[1;34m$@\033[0m"
}

function show_info {
    echo -e "$@"
}

function show_question {
    echo -e -n "$@"
}

function show_success {
    echo -e "\033[1;32m$@\033[0m"
}

function show_error {
    echo -e "\033[1;31m$@\033[m" 1>&2
}

function refresh_steps {
    steps=()
    stepnames=()
    local stepname=""

    while IFS= read -r step; do
        stepname=$(basename "${step}")
        stepname="${stepname%%.step}"
        stepname="${stepname#*_}"
        steps+=("$step")
        stepnames+=("$stepname")
    done < <(find "$stepsdir" -maxdepth 1 -type f -name "*.step" | sort -V)
}

function list_steps {
    local stepname=""

    for ((i = 0; i < ${#steps[@]}; i++)); do
        stepname=$(basename "${steps[i]}")
        stepname="${stepname%%.step}"
        stepname="${stepname#*_}"
        stepnames+=("$stepname")

        echo "$(($i+1)). $stepname"
    done
}

function count_steps {
    echo "${#steps[@]}"
}

function execute_step {
    local step="${steps[$(($1-1))]}"
    local auto=1

    if [ ! -f "$step" ]; then
        show_error "Step \"$step\" can't be found!"
        return 1
    fi

    if [ "$2" = "auto" ]; then
        auto=0
    fi

    ## Run script
    (source "$step")
    local result=$?
    echo ""

    ## Validate outcome
    if [ $result -ne 0 ]; then
        show_error "Step failed ($1)"

        if [ $auto -ne 0 ]; then
            echo ""
            show_question "Press any key to continue..." && read -n 1 dummy
        fi
        return 1
    else
        show_success "Step completed successfully!"

        if [ $auto -ne 0 ]; then
            echo ""
            show_question "Press any key to continue..." && read -n 1 dummy
        fi
        return 0
    fi
}

function insert_step {
    local path="$1"
    local name="$2"
    local append=0
    local order=0

    ## Make sure that order is numeric before assigning
    if [[ $3 =~ ^[0-9]+$ ]]; then
        append=1
        order=$3
    fi

    ## Loop through steps and rename them appropriately
    refresh_steps
    local stepno=1
    local step=""

    ## Loop through all steps
    for ((i = 0; i < ${#steps[@]}; i++)); do
        step="${steps[i]}"
        ## If file is to be appended at end of list
        ## Then just loop through them all and add it at the end
        if [ $append -eq 0 ]; then
            if [ "$step" != "$stepsdir/${stepno}_${stepnames[$i]}.step" ]; then
                mv "$step" "$stepsdir/${stepno}_${stepnames[$i]}.step"
            fi
        else
            ## If the file has been appended already
            ## make sure that the remaining get correct index
            if [ $stepno -gt $order ]; then
                if [ "$step" != "$stepsdir/$(($stepno+1))_${stepnames[$i]}.step" ]; then
                    mv "$step" "$stepsdir/$(($stepno+1))_${stepnames[$i]}.step"
                fi
            else
                ## Add the file at step if at correct index
                if [ $stepno -eq $order ]; then
                    mv "$path" "$stepsdir/${stepno}_$name.step"

                    if [ "$step" != "$stepsdir/$(($stepno+1))_${stepnames[$i]}.step" ]; then
                        mv "$step" "$stepsdir/$(($stepno+1))_${stepnames[$i]}.step"
                    fi
                else
                    if [ "$step" != "$stepsdir/${stepno}_${stepnames[$i]}.step" ]; then
                        mv "$step" "$stepsdir/${stepno}_${stepnames[$i]}.step"
                    fi
                fi
            fi
        fi

        stepno=$(($stepno+1))
    done

    ## If we're to append at the end
    if [ $append -eq 0 ]; then
        mv "$path" "$stepsdir/${stepno}_$name.step"
    fi

    refresh_steps
    return 0
}

function reorder_steps {
    ## Loop through steps and rename them appropriately
    refresh_steps
    local stepno=1
    local step=""

    ## Rename them so that they are properly ordered
    for ((i = 0; i < ${#steps[@]}; i++)); do
        step="${steps[i]}"

        if [ "$step" != "$stepsdir/${stepno}_${stepnames[$i]}.step" ]; then
            mv "$step" "$stepsdir/${stepno}_${stepnames[$i]}.step"
        fi

        stepno=$(($stepno+1))
    done

    refresh_steps
    return 0
}

##-----------Views-----------##
## Main menu
function main {
    local reply=""

    show_heading "What would you like to do?"
    echo ""
    echo "1. Run a step"
    echo "2. Create a step"
    echo "3. Manage steps"
    echo "4. Run through all steps automatically"
    echo "5. Edit global configuration file"
    echo "q. Quit"
    echo ""
    show_question "Enter your choice: " && read reply

    ## Run the user's choice
    case $reply in
        1) clear && run_step;; # Run a step
        2) clear && create_step;; # Create a step
        3) clear && manage_steps;; # Manage steps
        4) clear && autorun_steps;; # Autorun all configured steps
        5) clear && editor "$globalspath" && clear && main;; # Edit the global variables
        [Qq]* ) echo "" && exit 0;; # Quit
        * ) clear && show_error "\aNot an option, try again." && main;;
    esac
}

## Run a step
function run_step {
    local reply=""
    local index=0
    show_heading "Which step would you like to run? (\"b\" to go back)"
    echo ""

    ## Choose a step
    refresh_steps
    list_steps
    echo "b. Back"
    echo ""
    show_question "Enter your choice: " && read reply

    case $reply in
        [Bb]*) clear && main;;
        *)
            ## Verify numeric
            if ! [[ $reply =~ ^[0-9]+$ ]]; then
                clear && show_error "\aInput is not a number!\n" && run_step
            else
                # Verify the step exists
                if [ $reply -lt 1 ] || [ $reply -gt $(count_steps) ]; then
                    clear && show_error "\aNot an option, try again.\n" && run_step
                else
                    ## Run selected step
                    echo ""
                    index=$(($reply-1))
                    show_heading "Running: \"${stepnames[$index]}\""
                    echo ""
                    execute_step $reply

                    clear && run_step
                fi
            fi
        ;;
    esac
}

## Create a step
function create_step {
    local proceed=1
    local tempscript=1
    local script=""
    local name=""
    local order=""
    show_heading "Creating a new step (\"b\" to go back)"
    echo ""

    ## Script path
    while [ $proceed -ne 0 ]; do
        show_question "Script to import (Empty to create a new script): " && read script

        case $script in
            [Bb]) clear && main;;
            *)
                ## Create script
                if [ -z "$script" ]; then
                    script="$stepsdir/.new-script.tmp"
                    editor "$script"

                    if [ -f "$script" ]; then
                        proceed=0
                    else
                        show_error "\n\aYou need to save the file!\n"
                    fi
                ## Import Script
                else
                    ## Support tilde for "home"
                    if [ "${script:0:1}" = "~" ]; then
                        script="${script#~*}"
                        script="${HOME}${script}"
                    fi

                    if [ ! -f "$script" ]; then
                        echo ""
                        show_error "\aFile can't be found!\n"
                    else
                        cp "$script" "$stepsdir/.new-script.tmp"
                        script="$stepsdir/.new-script.tmp"
                        proceed=0
                    fi
                fi
            ;;
        esac
    done

    ## Step name
    show_question "Step name (only use characters allowed in a Linux filesystem): " && read name

    case $name in
        [Bb]) clear && main;;
    esac

    ## Step execution order
    proceed=1

    while [ $proceed -ne 0 ]; do
        refresh_steps

        # Skip asking where to insert if there are no previous steps
        if [ -z "$(echo "${steps[@]}")" ]; then
            order=""
            proceed=0
        else
            echo ""
            list_steps
            echo ""
            show_question "Execution order (Empty to insert at end): " && read order
        fi

        case $order in
            [Bb]*) clear && main;;
            *)
                ## If order is empty we just insert at end
                if [ -z "$order" ]; then
                    insert_step "$script" "$name"
                    proceed=0
                else
                    ## Verify input
                    if ! [[ $order =~ ^[0-9]+$ ]]; then
                        show_error "\aInput is not a number!\n"
                    else
                        if [ $order -lt 1 ] || [ $order -gt $(count_steps) ]; then
                            clear && show_error "\aNot an option, try again.\n"
                        else
                            insert_step "$script" "$name" $order
                            proceed=0
                        fi
                    fi
                fi
            ;;
        esac
    done

    ## Delete tempscript
    rm -f "$script"

    echo ""
    show_success "Step created successfully!"
    echo ""
    show_question "Press any key to continue... " && read -n 1 dummy

    clear && main
}

function manage_steps {
    ## Select step to edit
    local proceed=1
    local step=0
    local action=""

    while [ $proceed -ne 0 ]; do
        show_heading "Manage what step? (\"b\" to go back)"
        echo ""
        refresh_steps
        list_steps
        echo ""
        show_question "Step: " && read step

        case $step in
            [Bb]*) clear && main;;
            *)
                if ! [[ $step =~ ^[0-9]+$ ]]; then
                    clear && show_error "\aInput is not a number!\n"
                else
                    if [ $step -lt 1 ] || [ $step -gt $(count_steps) ]; then
                        clear && show_error "\aNot an option, try again.\n"
                    else
                        proceed=0
                    fi
                fi
            ;;
        esac
    done

    ## Select action
    proceed=1
    echo ""

    while [ $proceed -ne 0 ]; do
        show_heading "What action do you want to perform?"
        echo ""
        echo "1. Edit step"
        echo "2. Delete"
        echo "b. Back"
        echo ""
        show_question "Action: " && read action

        case $action in
            [Bb]*) clear && proceed=0 && manage_steps;; # Back
            1) clear && proceed=0 && edit_step $step;; # Edit
            2) clear && proceed=0 && delete_step $step;; # Delete
            *) clear && show_error "\aNot an option, try again.\n" ;;
        esac
    done
}

function edit_step {
    local index=$(($1-1))
    local proceed=1
    local samefile=1
    local script=""
    local name=""
    local order=0
    local tempscript=1

    show_heading "Editing \"${stepnames[$index]}\" (\"b\" to go back)"
    echo ""

    ## Script path
    while [ $proceed -ne 0 ]; do
        show_question "Script to import (${steps[$index]}) (Empty to skip change, \"e\" to edit file): " && read script

        case $script in
            [Bb]) clear && main;;
            ## Edit script with editor
            [Ee])
                editor "${steps[$index]}"
                script="${steps[$index]}"
                samefile=0
                proceed=0
            ;;
            *)
                ## Create script
                if [ -z "$script" ]; then
                    script="${steps[$index]}"
                    samefile=0
                    proceed=0
                ## Import Script
                else
                    if [ ! -f "$script" ]; then
                        echo ""
                        show_error "\aFile can't be found!\n"
                    else
                        proceed=0
                    fi
                fi
            ;;
        esac
    done

    ## Step name
    show_question "Step name (${stepnames[$index]}) (Empty to skip change, only use characters allowed in a Linux filesystem): " && read name

    case $name in
        [Bb]) clear && main;;
        *)
            if [ -z "$name" ]; then
                name="${stepnames[$index]}"
            fi
        ;;
    esac

    ## Step execution order
    proceed=1
    echo ""

    while [ $proceed -ne 0 ]; do
        refresh_steps
        list_steps
        echo ""
        show_question "Execution order ($(($index+1))) (Empty to insert at end): " && read order

        case $order in
            [Bb]*) clear && main;;
            *)
                ## Make a temporary file for the script
                ## so that the old one can be deleted
                ## and we can reinsert the script
                if [ $samefile -eq 0 ]; then
                    cp "$script" "$stepsdir/.new-script.tmp"
                    rm -f "$script"
                    script="$stepsdir/.new-script.tmp"
                    tempscript=0
                fi

                if [ -z "$order" ]; then
                    insert_step "$script" "$name"
                    proceed=0
                else
                    if ! [[ $order =~ ^[0-9]+$ ]]; then
                        show_error "\aInput is not a number!\n"
                    else
                        if [ $order -lt 1 ] || [ $order -gt $(count_steps) ]; then
                            clear && show_error "\aNot an option, try again.\n"
                        else
                            insert_step "$script" "$name" $order
                            proceed=0
                        fi
                    fi
                fi
            ;;
        esac
    done

    ## Delete tempscript if it was created now
    if [ $tempscript -eq 0 ]; then
        rm -f "$script"
    fi

    echo ""
    show_success "Step updated successfully!"
    echo ""
    show_question "Press any key to continue... " && read -n 1 dummy

    clear && manage_steps
}

function delete_step {
    local index=$(($1-1))
    local reply=""

    show_heading "Deleting ${stepnames[$index]}..."
    echo ""
    show_question "Are you sure you want to continue? (y/n) " && read -n 1 reply

    ## Either delete or abort
    case $reply in
        [Yy]*) rm -f "${steps[$index]}" && reorder_steps && clear && manage_steps;;
        * ) clear && show_error "\aAborted!\n" && manage_steps;;
    esac

    return 0
}

function autorun_steps {
    local proceed=1
    local reply=""
    local skipsteps=1

    while [ $proceed -ne 0 ]; do
        show_heading "Autorun configuration (\"b\" to go back):"
        echo ""
        show_question "Do you want the option to skip steps before they are executed? (y/n) " && read -n 1 reply

        ## Either delete or abort
        case $reply in
            [Yy]*) skipsteps=0 && proceed=0;;
            [Nn]*) skipsteps=1 && proceed=0;;
            [Bb]*) proceed=0 && clear && main;;
            *) clear && show_error "\aNot an option, try again.\n";;
        esac
    done

    echo ""
    echo ""
    show_heading "Running through all configuration steps (\"a\" to abort):"
    echo ""
    refresh_steps
    list_steps
    echo ""
    show_question "Press any key to continue... " && read -n 1 reply

    ## Option to abort
    case $reply in
        [Aa]*) clear && main;;
    esac

    ## Loop through all steps and run them
    for ((i = 0; i < ${#steps[@]}; i++)); do
        echo ""
        show_heading "${stepnames[$i]}:"
        echo ""

        ## Give the option to skip the step
        if [ $skipsteps -eq 0 ]; then
            show_question "Press any key to continue... (\"s\" to skip and \"a\" to abort) " && read -n 1 reply

            case $reply in
                [Ss]*) echo -e "\n\nSkipped" && continue;;
                [Aa]*) clear && show_error "\aOperation aborted!\n" && main && break;;
            esac
        fi

        execute_step $(($i+1)) auto
    done

    echo ""
    show_question "Press any key to continue..." && read -n 1 dummy
    clear && main
}

main
exit 0
