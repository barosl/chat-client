this.localStorage ?= do ->
    read_ck = (name) ->
        for ck in document.cookie.split ';'
            while ck.charAt(0) == ' ' then ck = ck[1..]
            if ck.indexOf(name+'=') == 0 then return decodeURIComponent ck[name.length+1..]
        return null

    write_ck = (name, val, days) ->
        expires = if days
            date = new Date
            date.setTime date.getTime() + 3600*24*1000*days
            '; expires='+date.toUTCString()
        else ''
        document.cookie = "#{name}=#{encodeURIComponent(val)}#{expires}; path=/"

    try data = (JSON.parse read_ck 'localStorage') ? {}
    catch then data = {}

    data.update = -> write_ck 'localStorage', (JSON.stringify data), 3650

    return data