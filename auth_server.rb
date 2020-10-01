class Wafer
    NO_LOG_CMDS = ["passlogin", "passwordauth"]
    NO_USER_VERIFY_CMDS = ["emailused", "emaillookup"]
    KEYCODE_VERIFY_CMDS = ["checkaccess", "convertaccount", "getping", "getprop", "pinguser"]
    HASH_VERIFY_CMDS = ["md5login", "md5auth"]
    PASSWORD_VERIFY_CMDS = ["passwordlogin", "passwordauth"]

    def auth_respond(conn, first_message)
        if first_message[0][0] == ":"
            secure_auth = true
            user_name = first_message[0][1..-1]
            code = first_message[1]
            command = first_message[2]
            @seq_numbers[conn] = first_message[3]
            message = first_message[4..-1]
        else
            secure_auth = false
            command = first_message[0]
            @seq_numbers[conn] = first_message[1]
            user_name = first_message[2]
            code = false
            message = first_message[3..-1]
        end

        if command == "" || user_name == ""
            send_error(conn, "BAD INPUT")
        end

        uid = @repo.uid_by_name(user_name)

        if NO_LOG_CMDS.include?(command)
            # Don't log passwords
            log("Recorded command #{command.inspect} for user #{user_name.inspect}")
        else
            log("Auth server: #{first_message.inspect}")
        end

        # All commands but two require verifying the user isn't deleted, banned, etc.
        unless NO_USER_VERIFY_CMDS.include?(command)
            allowed, err = @repo.is_user_ok(uid)
            return send_error(conn, err) unless allowed
        end

        # Some commands need the keycode to be valid if supplied
        if KEYCODE_VERIFY_CMDS.include?(command) && code
            allowed, err = @repo.is_keycode_ok(uid, code)
            return send_error(conn, err) unless allowed
        end

        if HASH_VERIFY_CMDS.include?(command)
            allowed, err = @repo.is_hash_ok(uid, message[0])
            return send_error(conn, err) unless allowed
        end

        if PASSWORD_VERIFY_CMDS.include?(command)
            allowed, err = @repo.is_password_ok(uid, message[0])
            return send_error(conn, err) unless allowed
        end

        case command

        when "checkaccess"
            if @repo.user_has_access?(uid, message[0])
                return send_ok(conn, "ACCESS")
            else
                return send_error(conn, "NOAUTH")
            end

        when "convertaccount"
            if message[0] == "premium"
                @repo.user_set_flag(uid, "premium")
                return send_ok(conn, "premium")
            elsif message[0] == "basic"
                @repo.user_unset_flag(uid, "premium")
                return send_ok(conn, "basic")
            else
                return send_error(conn, "Unknown conversion (#{message[0]})")
            end

        when "emaillookup"
            user = @repo.user_by_field("email", user_name)
            if user
                return send_ok(conn, user["name"])
            else
                return send_error(conn, "no such email")
            end

        when "emailused"
            user = @repo.user_by_field("email", user_name)
            if user
                return send_ok(conn, "YES")
            else
                return send_error(conn, "no such email")
            end

        when "getping"
            # We don't do real email pings with this server
            user = @repo.user_by_id(uid)
            if user
                return send_ok(conn, "#{uid} #{user["email"]} 17171717171717171717")
            else
                return send_error(conn, "NO PING")
            end

        when "getprop"
            if secure_auth
                prop = message[1]
            else
                prop = message[0]
            end

            user = @repo.user_by_id(uid)
            return send_ok(conn, user[prop])

        when "keycodeauth"
            code = message[0] unless code

            allowed, err = @repo.is_keycode_ok(uid, code)
            return send_error(conn, err) unless allowed

            return send_error(conn, "TOS") unless @repo.user_has_tos?(uid)
            return send_error(conn, "USER HAS NO EMAIL") unless @repo.user_has_verified_email?(uid)

            return send_auth_status(conn, uid)

        when "md5login"
            return send_ok(conn, @repo.user_keycode(uid))

        when "md5auth"
            return send_auth_status(conn, uid)

        when "passwordlogin"
            return send_ok(conn, @repo.user_keycode(uid))

        when "passwordauth"
            return send_auth_status(conn, uid)

        when "pinguser"
            return send_ok(conn, "OK")

        when "setemail"
            @repo.user_set_email(uid, message[0])
            return send_ok(conn, "YES")

        when "tempkeycode"
            return send_ok(conn, @repo.user_keycode(uid))

        when "tempguarantee"
            return send_error(conn, "DOES NOT SUPPORT")
        end

        return send_error(conn, "BAD COMMAND(#{command.inspect})")
    end

    def send_auth_status(conn, uid)
        user_type = @repo.user_account_type(uid)
        user_status = @repo.user_account_status(uid)
        user_string = "(#{user_type}, #{user_status})"

        if @repo.user_is_paid?(uid)
            if user_type == "trial"
                return send_ok(conn, "TRIAL #{@repo.user_next_stamp(uid)} #{user_string}")
            elsif ["developer", "staff", "free"].include?(user_type)
                return send_ok(conn, "PAID 0 #{user_string}")
            else
                return send_ok(conn, "PAID #{@repo.user_next_stamp(uid)} #{user_string}")
            end
        else
            return send_ok(conn, "UNPAID #{user_string}")
        end
    end
end
