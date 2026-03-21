#!/bin/bash
# =============================================================================
# Student terminal entrypoint — creates team users with security hardening
#
# Complexity: O(TEAM_COUNT) — linear pass creating users
# =============================================================================

# --- Constants (sourced from env with sensible defaults) ---------------------
readonly TEAM_COUNT="${TEAM_COUNT:-10}"
readonly SHELLINABOX_PORT="${SHELLINABOX_PORT:-4200}"
readonly CTFD_PORT="${CTFD_PORT:-8000}"
readonly NOTES_SRC="/opt/bash_notes.txt"
readonly DARK_CSS="/opt/cyber-dark.css"
readonly LIGHT_CSS="/etc/shellinabox/options-enabled/00_White On Black.css"
readonly HOME_DIR_MODE=700
readonly SUDOERS_MODE=440

# Allowed sudo commands — tools that require raw socket privileges
readonly -a SUDO_ALLOWED=(
    /usr/bin/nmap
    /usr/bin/tcpdump
    /usr/sbin/traceroute
    /usr/bin/traceroute
)

# --- Functions ---------------------------------------------------------------

# Create a single team user with restricted sudo and isolated home directory
create_team_user() {
    local index=$1
    local user="team${index}"
    local pass_var="TEAM${index}_PASS"
    local pass="${!pass_var:-scan4flags${index}}"

    # Create user if not exists
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
    fi
    echo "${user}:${pass}" | chpasswd

    # Restricted sudo: only network analysis tools, no shell access
    local sudoers_cmds
    sudoers_cmds=$(IFS=', '; echo "${SUDO_ALLOWED[*]}")
    printf '%s ALL=(ALL) NOPASSWD: %s\n' "$user" "$sudoers_cmds" \
        > "/etc/sudoers.d/${user}"
    chmod "$SUDOERS_MODE" "/etc/sudoers.d/${user}"

    # Isolate home directory — users cannot read each other's files
    chmod "$HOME_DIR_MODE" "/home/${user}"

    # Provide course notes
    cp "$NOTES_SRC" "/home/${user}/bash_notes.txt"
    chown "${user}:${user}" "/home/${user}/bash_notes.txt"

    # Configure shell environment (idempotent — skips if already done)
    if ! grep -q "nmap-lab" "/home/${user}/.bashrc" 2>/dev/null; then
        cat >> "/home/${user}/.bashrc" <<BASHRC
CTFD_HOST=\${CTFD_HOST:-\$(getent hosts host.docker.internal | awk "{print \\\$1}" 2>/dev/null || echo "localhost")}
echo ""
echo "  SUBMIT FLAGS: http://\${CTFD_HOST}:${CTFD_PORT}"
echo "  Format: FLAG{some_text_here}"
echo ""
export PS1="\[\e[32m\]\u@nmap-lab\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\\$ "
alias notes="less ~/bash_notes.txt"
alias cheatsheet="less ~/bash_notes.txt"
BASHRC
    fi
}

# --- Main: create all team users ---------------------------------------------
for i in $(seq 1 "$TEAM_COUNT"); do
    create_team_user "$i"
done

# --- Start shellinabox with LOGIN prompt and dark theme ----------------------
exec shellinaboxd \
    --no-beep \
    --disable-ssl \
    --port="$SHELLINABOX_PORT" \
    --user-css "Cyber Dark:+${DARK_CSS},White On Black:-${LIGHT_CSS}" \
    --service=/:LOGIN
