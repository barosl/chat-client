RECONN_SECS = 5
DEFAULT_CHAN = '#default'

angular.module 'chat', []
    .config ($sceProvider) ->
        $sceProvider.enabled false if ie_7?

    .controller 'ChatCtrl', ($scope) ->
        $scope.init = ->
            $scope.connected = false
            $scope.nick = ''
            $scope.users = []
        $scope.init()

        $scope.msgs = []

$ ->
    $scope = angular.element($('body')).scope()

    [sock, user] = []
    init = ->
        sock = null
        user = {}
    init()

    send = (data) -> sock.send JSON.stringify data

    set_nick = (nick) ->
        set_nick.desired_nick = nick
        send nick: nick

    conn = ->
        sock = new WebSocket cfg.url

        sock.onopen = (ev) ->
            $scope.$apply -> $scope.connected = true

            add_msg 'Successfully connected', 'info'

            nick = localStorage.chat_nick ? ''
            set_nick nick
            $scope.$apply -> $scope.nick = nick

        sock.onclose = (ev) ->
            $scope.$apply -> $scope.init()

            add_msg "Connection closed. Reconnecting in #{RECONN_SECS} seconds (Error code: #{ev.code})", 'err'

            setTimeout ->
                conn()
            , RECONN_SECS*1000

        sock.onmessage = (ev) ->
            try
                data = JSON.parse ev.data

                if 'msg' of data
                    add_msg data.msg
                else if 'nick' of data
                    if not user.nick?
                        send join: DEFAULT_CHAN
                    user.nick = data.nick
                    $scope.$apply -> $scope.nick = user.nick
                else if 'err' of data
                    $scope.$apply -> $scope.nick = user.nick ? localStorage.chat_nick
                    add_msg data.err, 'err'

                    if data.err == 'Nickname already in use'
                        set_nick set_nick.desired_nick+'+'
                else if 'users' of data
                    $scope.$apply -> $scope.users = data.users
                else if 'msgs' of data
                    add_msgs data.msgs
                else if 'join' of data
                    add_msg "#{data.user} has joined #{data.join}", 'info'
                else if 'part' of data
                    add_msg "#{data.user} has parted #{data.part}", 'info'
                    if data.user == user.nick
                        $scope.$apply -> $scope.users = []
                else
                    throw new SyntaxError 'Invalid message type'

            catch e
                add_msg 'Invalid server response', 'err'
                console.log "Invalid server response: #{ev.data}"

    $('#chat-input').keydown (ev) ->
        if ev.which != 13 or ev.target.value == '' then return
        ev.preventDefault()
        [msg, ev.target.value] = [ev.target.value, '']

        msg = $.trim(msg)
        if not msg then return

        if not $scope.connected
            add_msg 'Not connected', 'err'
            return

        if msg == '/join'
            send join: DEFAULT_CHAN
        else if msg == '/part'
            send part: DEFAULT_CHAN
        else
            send msg: msg, chan: DEFAULT_CHAN

    $('#chat-nick').keydown (ev) ->
        if ev.which != 13 or $scope.nick == (user.nick ? null) then return
        ev.preventDefault()

        if $scope.nick == ''
            $scope.$apply -> $scope.nick = user.nick ? localStorage.chat_nick ? ''
            $('#chat-input').focus()
            return

        set_nick $scope.nick

        localStorage.chat_nick = $scope.nick

        $('#chat-input').focus()

    $('#users-link').click (ev) ->
        ev.preventDefault()
        $('#users').toggle()

    add_msg = (msg, type='normal') ->
        $scope.$apply -> $scope.msgs.push type: type, msg: msg
        window.scrollTo 0, document.body.scrollHeight

    add_msgs = (msgs) ->
        $scope.$apply -> Array::push.apply $scope.msgs, (type: 'normal', msg: x for x in msgs)
        window.scrollTo 0, document.body.scrollHeight

    conn()
    $('#chat-input').focus()
