host = process.env.HUBOT_TEAMSPEAK_IP
user = process.env.HUBOT_TEAMSPEAK_USER
password = process.env.HUBOT_TEAMSPEAK_PASSWORD
enabled = true

TeamSpeak = require 'node-teamspeak'
util = require 'util'

module.exports = (robot) ->
  unless host
    robot.logger.warning "Missing TeamSpeak IP!"
    enabled = false

  unless user
    robot.logger.warning "Missing TeamSpeak ServerQuery user"
    enabled = false

  unless password
    robot.logger.warning "Missing TeamSpeak ServerQuery password"
    enabled = false

  if enabled
    client = new TeamSpeak host
    active_users = []
    rooms = process.env.HUBOT_TEAMSPEAK_OUT_ROOM.split(",")

    send_message = (message) ->
      for room in rooms
        robot.send {room: room}, message

    client.send "login", {client_login_name: user, client_login_password: password}, (err, resp) ->
      client.send "use", {sid: 1}, ->
        robot.logger.info "Connected"
        client.send "servernotifyregister", {event: "server"}

      client.on "cliententerview", (event) ->
        active_users[event.clid] = event.client_nickname
        send_message active_users[event.clid] + " has entered TeamSpeak"

      client.on "clientleftview", (event) ->
        send_message active_users[event.clid] + " has left TeamSpeak. Reason: " + event.reasonmsg
        active_users[event.clid] = ""

      setInterval ->
        client.send "whoami", (err, resp) ->
          # robot.logger.info "KeepAlive Ping"
      , 180000
      true

      robot.respond /teamspeak/i, (msg) ->
        client.send "clientlist", (err, resp) ->
          users = []

          for el in resp
            if el.client_type isnt 1
              users.push el.client_nickname

          msg.send "Currently in TeamSpeak: " + users.join(", ")
