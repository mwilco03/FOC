#!/bin/bash
set -e

# Create team users with passwords from environment
for i in $(seq 1 ${STUDENT_COUNT:-5}); do
    USERNAME="team${i}"
    PASS_VAR="TEAM${i}_PASS"
    PASSWORD="${!PASS_VAR:-hunt4threats${i}}"

    if ! id "$USERNAME" &>/dev/null; then
        useradd -m -s /bin/bash "$USERNAME"
    fi
    echo "${USERNAME}:${PASSWORD}" | chpasswd

    # Passwordless sudo
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USERNAME}"
    chmod 440 "/etc/sudoers.d/${USERNAME}"

    # Copy cheatsheet
    cp /opt/bash_notes.txt "/home/${USERNAME}/notes.txt"
    chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/notes.txt"

    # Configure bashrc
    cat >> "/home/${USERNAME}/.bashrc" << 'BASHRC'

# Threat Hunt Lab
VICTIM_HOST="${VICTIM_HOST:-host.docker.internal}"
VICTIM_PORT=$((59850 + ${USER##team}))
KIBANA_HOST="${KIBANA_HOST:-host.docker.internal}"
ELK_URL="http://${KIBANA_HOST}:5601"
ARKIME_URL="http://${KIBANA_HOST}:8005"
CTFD_HOST="${CTFD_HOST:-host.docker.internal}"
CTFD_URL="http://${CTFD_HOST}:8000"

echo ""
echo -e "\033[32m  THREAT HUNT LAB\033[0m"
echo -e "  Scoreboard:  \033[36m${CTFD_URL}\033[0m"
echo -e "  Kibana:      \033[36m${ELK_URL}\033[0m"
echo -e "  Arkime:      \033[36m${ARKIME_URL}\033[0m"
echo -e "  Victim VM:   \033[33mpwsh -c 'Enter-PSSession -ComputerName ${VICTIM_HOST} -Port ${VICTIM_PORT} -Credential ${USER}'\033[0m"
echo ""

alias notes='less ~/notes.txt'
alias cheatsheet='less ~/notes.txt'
alias victim='pwsh -c "Enter-PSSession -ComputerName ${VICTIM_HOST} -Port ${VICTIM_PORT} -Credential ${USER}"'

PS1='\[\033[01;32m\]\u@threat-hunt\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
BASHRC
done

# Start shellinabox
exec /usr/bin/shellinaboxd \
    --no-beep \
    --disable-ssl \
    --port=4200 \
    --css="/opt/cyber-dark.css" \
    --service="/:LOGIN"
