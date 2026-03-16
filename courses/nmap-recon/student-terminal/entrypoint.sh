#!/bin/bash
# Entrypoint: creates all team users, presents login prompt

# Create all 10 team users
for i in $(seq 1 10); do
    PASS_VAR="TEAM${i}_PASS"
    PASS="${!PASS_VAR:-scan4flags${i}}"
    USER="team${i}"

    if ! id "$USER" &>/dev/null; then
        useradd -m -s /bin/bash "$USER"
    fi
    echo "${USER}:${PASS}" | chpasswd

    # Passwordless sudo
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}
    chmod 440 /etc/sudoers.d/${USER}

    # Copy notes to home
    cp /opt/bash_notes.txt /home/${USER}/bash_notes.txt
    chown ${USER}:${USER} /home/${USER}/bash_notes.txt

    # Setup .bashrc (only if not already configured)
    if ! grep -q "nmap-lab" /home/${USER}/.bashrc 2>/dev/null; then
        cat >> /home/${USER}/.bashrc <<'BASHRC'
CTFD_HOST=${CTFD_HOST:-$(getent hosts host.docker.internal | awk "{print \$1}" 2>/dev/null || echo "localhost")}
echo ""
echo "  SUBMIT FLAGS: http://${CTFD_HOST}:8000"
echo "  Format: FLAG{some_text_here}"
echo ""
export PS1="\[\e[32m\]\u@nmap-lab\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ "
alias notes="less ~/bash_notes.txt"
alias cheatsheet="less ~/bash_notes.txt"
BASHRC
    fi
done

# Shell-in-a-Box with LOGIN prompt and dark theme
exec shellinaboxd \
    --no-beep \
    --disable-ssl \
    --port=4200 \
    --user-css "Cyber Dark:+/opt/cyber-dark.css,White On Black:-/etc/shellinabox/options-enabled/00_White On Black.css" \
    --service=/:LOGIN
