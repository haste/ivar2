scale = (val, max, frm, to) ->
    x1, x2 = '', ''
    max = ivar2.util.trim(max or '')
    val = tonumber(val)
    if tonumber(max)
      max = tonumber(max)
    else
      if #max
        to = max
        x2 = max
        max = 10

    pos = math.min(val, max)
    pos = math.max(pos, 0)


    unless frm
      x1 = ''
    else
      x1 = frm
    unless to
      x2 = ''
    else
      x2 = to

    unless to
      if frm ~= nil
        x2 = frm


    char = '█'

    left = char\rep(pos)
    right = char\rep(max-pos)

    return "#{x1}[#{ivar2.util.green left}#{ivar2.util.bold ivar2.util.italic ivar2.util.yellow 'X'}#{ivar2.util.red right}]#{x2}"

scalew = (s, d, val, max, frm, to) =>
  say(scale(val, max, frm, to))

PRIVMSG:
  '^%pscale ([0-9]+)$': scalew
  '^%pscale ([0-9]+) ([0-9]+)$': scalew
  '^%pscale ([0-9]+) ([a-zA-ZæøåÆØÅ%-]+)$': scalew
  '^%pscale ([0-9]+) ([0-9]+) ([a-zA-ZæøåÆØÅ#%-]+)$': scalew
  '^%pscale ([0-9]+) ([0-9]+) ([a-zA-ZæøåÆØÅ#%-]+)$': scalew
  '^%pscale ([0-9]+) ([0-9]+) (.+) (.+)$': scalew
  '^%ptscale ([0-9]+)$': (s, d, temp) =>
    say(scale(temp, 30, 'freezing', 'hot as fuck'))
