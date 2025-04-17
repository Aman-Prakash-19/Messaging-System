# DB Connection Details
DB_HOST="sql12.freesqldatabase.com"
DB_PORT="3306"
DB_USER="sql12773185"
DB_PASS="vT3SfyZpSC"
DB_NAME="sql12773185"

logged_in_user_id=""
logged_in_username=""

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

function mysql_exec() {
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "$1"
}

function banner() {
    echo -e "${CYAN}"
    echo "==========================================="
    echo "        💬 Terminal Chat Application       "
    echo "==========================================="
    echo -e "${NC}"
}

function pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read
}

function signup() {
    clear
    banner
    echo -e "${BLUE}🔐 Sign Up${NC}"
    read -p "Username: " username
    read -s -p "Password: " password
    echo

    result=$(mysql_exec "INSERT INTO users01 (username, password) VALUES ('$username', '$password');" 2>&1)

    if [[ "$result" == *"Duplicate entry"* ]]; then
        echo -e "${RED}❌ Username already exists.${NC}"
    else
        echo -e "${GREEN}✅ Successfully signed up!${NC}"
    fi
    pause
}

function login() {
    clear
    banner
    echo -e "${BLUE}🔑 Login${NC}"
    read -p "Username: " username
    read -s -p "Password: " password
    echo

    user_id=$(mysql_exec "SELECT id FROM users01 WHERE username='$username' AND password='$password';")

    if [ -z "$user_id" ]; then
        echo -e "${RED}❌ Incorrect username or password.${NC}"
        pause
        return 1
    else
        logged_in_user_id=$user_id
        logged_in_username=$username
        mysql_exec "UPDATE users01 SET status='online' WHERE id=$logged_in_user_id;"
        echo -e "${GREEN}✅ Logged in as $username${NC}"
        pause
        return 0
    fi
}

function logout() {
    mysql_exec "UPDATE users01 SET status='offline' WHERE id=$logged_in_user_id;"
    logged_in_user_id=""
    logged_in_username=""
}

function list_users() {
    clear
    banner
    echo -e "${CYAN}👥 Available Users to Chat:${NC}"

    users=$(mysql_exec "SELECT id, username, status FROM users01 WHERE id != $logged_in_user_id;")

    if [ -z "$users" ]; then
        echo -e "${YELLOW}No other users found!${NC}"
        pause
        return
    fi

    declare -A user_map
    index=1
    while IFS=$'\t' read -r id name status; do
        if [[ "$status" == "online" ]]; then
            echo -e "$index) $name - ${GREEN}Online${NC}"
        else
            echo -e "$index) $name - ${RED}Offline${NC}"
        fi

        user_map[$index]=$id
        ((index++))
    done <<< "$users"

    echo -ne "${BLUE}Choose a user number to chat with (0 to back): ${NC}"
    read choice

    if [ "$choice" == "0" ]; then
        return
    elif [ -n "${user_map[$choice]}" ]; then
        chat_menu "${user_map[$choice]}"
    else
        echo -e "${RED}❌ Invalid selection.${NC}"
        pause
    fi
}

function chat_menu() {
    receiver_id=$1
    receiver_name=$(mysql_exec "SELECT username FROM users01 WHERE id = $receiver_id;")

    while true; do
        clear
        banner
        echo -e "${BLUE}💬 Chat with $receiver_name${NC}"
        echo "1) 📤 Send Message"
        echo "2) 📥 View Messages"
        echo "3) 🔙 Back"
        read -p "Choose: " option

        case "$option" in
            1)
                read -p "Enter your message: " msg
                mysql_exec "INSERT INTO messages01 (sender_id, receiver_id, message) VALUES ($logged_in_user_id, $receiver_id, '$msg');"
                echo -e "${GREEN}✅ Message sent!${NC}"
                pause
                ;;
            2)
                clear
                banner
                echo -e "${YELLOW}📜 Chat History with $receiver_name:${NC}"

                mysql_exec "SELECT u.username, m.message, m.timestamp FROM messages01 m JOIN users01 u ON m.sender_id=u.id WHERE (sender_id=$logged_in_user_id AND receiver_id=$receiver_id) OR (sender_id=$receiver_id AND receiver_id=$logged_in_user_id) ORDER BY timestamp;" | while IFS=$'\t' read -r sender msg time; do
                    echo -e "${CYAN}[$time] $sender:${NC} $msg"
                done
                pause
                ;;
            3) return ;;
            *) echo -e "${RED}❌ Invalid option.${NC}"; pause ;;
        esac
    done
}

function main_menu() {
    while true; do
        clear
        banner
        echo -e "${CYAN}Welcome, $logged_in_username 👋${NC}"
        echo "1) 💬 Chat with a user"
        echo "2) 🚪 Logout"
        read -p "Choose: " option

        case "$option" in
            1) list_users ;;
            2) logout; return ;;
            *) echo -e "${RED}Invalid option.${NC}"; pause ;;
        esac
    done
}

# Entry Menu
while true; do
    clear
    banner
    echo "1) 🔑 Login"
    echo "2) 📝 Signup"
    echo "3) ❌ Exit"
    read -p "Choose: " option

    case "$option" in
        1)
            login && main_menu
            ;;
        2) signup ;;
        3)
            if [[ -n "$logged_in_user_id" ]]; then
                logout
            fi
            echo -e "${YELLOW}👋 See you next time!${NC}"
            exit
            ;;
        *) echo -e "${RED}Invalid input.${NC}"; pause ;;
    esac
done

