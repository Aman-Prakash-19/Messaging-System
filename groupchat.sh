#!/bin/bash

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

mysql_exec()
{
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "$1"
}

show_group_menu()
{
    while true; do
        clear
        banner
        echo -e "${BLUE}📢 Group Chat Menu${NC}"
        echo "1) ➕ Create Group"
        echo "2) 👥 View My Groups"
        echo "3) 🔙 Back"
        read -p "Choose: " choice

        case "$choice" in
            1) create_group ;;
            2) list_user_groups ;;
            3) return ;;
            *) echo -e "${RED}❌ Invalid option.${NC}"; pause ;;
        esac
    done
}

create_group()
{
    read -p "Enter new group name: " gname
    mysql_exec "INSERT INTO groups (name) VALUES ('$gname');"
    gid=$(mysql_exec "SELECT id FROM groups WHERE name = '$gname' ORDER BY id DESC LIMIT 1;")
    echo "$logged_in_user_id, $gid"
    mysql_exec "INSERT INTO group_members (group_id, user_id) VALUES ($gid, $logged_in_user_id);"
    echo -e "${GREEN}✅ Group '$gname' created.${NC}"
    pause
}

list_user_groups()
{
    groups=$(mysql_exec "SELECT g.id, g.name FROM groups g JOIN group_members gm ON g.id = gm.group_id WHERE gm.user_id = $logged_in_user_id;")
    if [[ -z "$groups" ]]; then
        echo -e "${YELLOW}⚠️ You are not in any groups.${NC}"; pause; return
    fi

    echo -e "${CYAN}📂 Your Groups:${NC}"
    mapfile -t group_array <<< "$groups"
    i=1
    for line in "${group_array[@]}"; do
        gid=$(cut -f1 <<< "$line")
        gname=$(cut -f2 <<< "$line")
        echo "$i) $gname"
        group_ids[$i]=$gid
        ((i++))
    done

    read -p "Choose a group: " choice
    selected_gid=${group_ids[$choice]}
    if [[ -n "$selected_gid" ]]; then
        group_action_menu "$selected_gid"
    else
        echo -e "${RED}❌ Invalid choice.${NC}"; pause
    fi
}

group_action_menu()
{
    gid=$1
    gname=$(mysql_exec "SELECT name FROM groups WHERE id = $gid;")
    while true; do
        clear
        banner
        echo -e "${BLUE}🔘 Group: $gname${NC}"
        echo "1) 📨 Send Group Message"
        echo "2) 📜 View Group Messages"
        echo "3) ⚙️  Manage Group"
        echo "4) 🔙 Back"
        read -p "Choose: " choice
        case "$choice" in
            1) send_group_message "$gid" ;;
            2) view_group_messages "$gid" ;;
            3) manage_group "$gid" ;;
            4) return ;;
            *) echo -e "${RED}❌ Invalid choice.${NC}"; pause ;;
        esac
    done
}

send_group_message()
{
    gid=$1
    read -p "Message: " msg
    mysql_exec "INSERT INTO messages01 (sender_id, group_id, message) VALUES ($logged_in_user_id, $gid, '$msg');"
    echo -e "${GREEN}✅ Message sent.${NC}"; pause
}

view_group_messages()
{
    gid=$1
    echo -e "${YELLOW}📜 Group Messages:${NC}"
    mysql_exec "SELECT u.username, m.message, m.timestamp FROM messages01 m JOIN users01 u ON u.id = m.sender_id WHERE m.group_id = $gid ORDER BY m.timestamp ASC;" | while IFS=$'\t' read -r user msg time; do
        echo -e "${CYAN}[$time] $user:${NC} $msg"
    done
    pause
}

manage_group()
{
    gid=$1
    while true; do
        clear
        banner
        echo -e "${BLUE}🛠 Manage Group ID $gid${NC}"
        echo "1) 👥 View Members"
        echo "2) ✏️ Change Group Name"
        echo "3) ➕ Add Members"
        echo "4) ➖ Remove Members"
        echo "5) 🔙 Back"
        read -p "Choose: " choice
        case "$choice" in
            1) view_group_members "$gid" ;;
            2) change_group_name "$gid" ;;
            3) add_to_group "$gid" ;;
            4) remove_from_group "$gid" ;;
            5) return ;;
            *) echo -e "${RED}❌ Invalid choice.${NC}"; pause ;;
        esac
    done
}

view_group_members()
{
    gid=$1
    echo -e "${CYAN}👥 Members of Group $gid:${NC}"
    mysql_exec "SELECT u.username FROM users01 u JOIN group_members gm ON u.id = gm.user_id WHERE gm.group_id = $gid;" | nl
    pause
}

change_group_name()
{
    gid=$1
    read -p "Enter new group name: " newname
    mysql_exec "UPDATE groups SET name = '$newname' WHERE id = $gid;"
    echo -e "${GREEN}✅ Group name updated.${NC}"
    pause
}

add_to_group()
{
    gid=$1
    read -p "Enter username to add: " uname
    uid=$(mysql_exec "SELECT id FROM users01 WHERE username = '$uname';")
    if [[ -n "$uid" ]]; then
        mysql_exec "INSERT INTO group_members (group_id, user_id) VALUES ($gid, $uid);"
        echo -e "${GREEN}✅ User added.${NC}"
    else
        echo -e "${RED}❌ User not found.${NC}"
    fi
    pause
}

remove_from_group()
{
    gid=$1
    read -p "Enter username to remove: " uname
    uid=$(mysql_exec "SELECT id FROM users01 WHERE username = '$uname';")
    if [[ -n "$uid" ]]; then
        mysql_exec "DELETE FROM group_members WHERE group_id = $gid AND user_id = $uid;"
        echo -e "${GREEN}✅ User removed.${NC}"
    else
        echo -e "${RED}❌ User not found.${NC}"
    fi
    pause
}

show_group_menu