class Wafer
    def ctl_respond
        return send_error(conn, "BAD INPUT") if message.size < 3 || message.size > 9

        return send_error(conn, "UNIMPLEMENTED")
    end
end
