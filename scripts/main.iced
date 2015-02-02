require.config({
  baseUrl: 'javascripts'
  paths: {
      jquery: 'jquery-1.11.2.min'
  }
})

require ['./state', 'jquery'], (STATE, $) ->

  DEBUG = true
  print = (x) ->
    if DEBUG
      console.log(x)

  ECHONEST_ID = 'YSN67FHUAZZDWQBSL'

  initSongData = (cb) ->
    url = 'http://developer.echonest.com/api/v4/song/search?' +
      (['api_key='+ECHONEST_ID
        'format=json'
        'results=10'
        'min_tempo=120'
        'mood=excited'
        'sort=song_hotttnesss-desc'
        'bucket=id:fma'
        'bucket=tracks'
        'limit=true'
        ].join('&'))

    await $.getJSON(url, defer res )

    fmaData = []
    songList = res.response.songs
    print(songList)
    await
      for song,i in songList
        url = 'http://freemusicarchive.org/api/get/tracks.jsonp?'
        $.ajax({
            url: url
            jsonp: "callback"
            dataType: "jsonp"
            data: ([
                'api_key=PZN1ZYVWOPFLCUR5'
                'track_id='+song.tracks[0].foreign_id[('fma:track:'.length)..]
              ].join('&'))
            success: defer(fmaData[i])
            error: (e) -> console.log(e.message)
        })
    print(fmaData)
    songFiles = (({ artist_name: song.dataset[0].artist_name, track_title: song.dataset[0].track_title, track_url: song.dataset[0].track_url, track_id: songList[i].tracks[0].id}) for song,i in fmaData)
    console.log(songFiles)
    STATE.songs.set(songFiles)
    cb(songFiles)

  initSongAnalysis = (songInfo) ->
    songAnalyses = []
    for track in songInfo
      url = 'http://developer.echonest.com/api/v4/track/profile?' +
        (['api_key='+ECHONEST_ID
          'format=json'
          'id='+track.track_id
          'bucket=audio_summary'
          ].join('&'))

      await $.getJSON(url, defer res )
      await $.getJSON(res.response.track.audio_summary.analysis_url, defer res )
      songAnalyses.push({song_info: track, analysis: res})
      STATE.song_analyses.set(songAnalyses)


  initGameData = () ->
    gs = {
      isPaused: true
      invincibilityTimer: 0
      didGetHitTimer: 0
      levelTime: 10
      elapsedTime: 0
      audio: {
        beatIndex: 0
        beats: []
        bars: []
        tatums: []
      }
      worldRot: 0
      player: {
        type: 0
        totalTypes: 2
        collisionRadius: 0.05
      }
      screenDims: {
        widthPX: 1024
        heightPX: 768
      }
      worldDims: {
        width: 1
        height: 3/4
      }
      input: {
        change: false
      }
    }

    STATE.set(gs)

  unless STATE.songs.read()?
    initSongData((songData) -> initSongAnalysis(STATE.songs.read()))

  # STATE.songs.set('')
  # initSongData()
  # initSongAnalysis(STATE.songs.read())

  console.log(STATE.song_analyses.read())
  document.getElementById('loading-msg').remove()

  # unless STATE.read()?
  initGameData()
  # else print("GAME NOT INITIALIZED")

  P = (() ->
      gameScreenCanvas = document.getElementById('game')
      backBufferCanvas = document.createElement('canvas')
      G = STATE.read()
      $(gameScreenCanvas).attr('width', G.screenDims.widthPX)
      $(gameScreenCanvas).attr('height', G.screenDims.heightPX)
      $(backBufferCanvas).attr('width', G.screenDims.widthPX)
      $(backBufferCanvas).attr('height', G.screenDims.heightPX)
      backBufferCanvas.width = G.screenDims.widthPX
      backBufferCanvas.width = G.screenDims.widthPX
      backBufferCanvas.height = G.screenDims.heightPX
      backBufferCanvas.height = G.screenDims.heightPX
      backBuffer = backBufferCanvas.getContext('2d')
      gameScreen = gameScreenCanvas.getContext('2d')

      events = []
      $(window).keydown (e) ->
        events.push(e)
        if e.keyCode is 32
          e.preventDefault()

      {
        swapBuffers: () -> gameScreen.drawImage(backBufferCanvas, 0, 0)
        backBuffer: backBuffer
        readInput: () ->
          read = events
          events = []
          read
      }
      )()

  step = (() ->
      lastTimestamp = null
      (timestamp) ->
        elapsed = timestamp - lastTimestamp

        G = guar(P.backBuffer, STATE.read(), elapsed)
        G.input = {}
        es = P.readInput()
        for e in es
          if e.keyCode is 32
            G.input.change = true

        STATE.set(G)
        lastTimestamp = timestamp
        window.requestAnimationFrame step)()

  typeColors = ['#FC3A8B', '#01B0F0']
  clearScreen = (ctx, screenDims, type) ->
    ctx.fillStyle = typeColors[type]
    ctx.fillRect(0,0, screenDims.widthPX,
                       screenDims.heightPX)

  drawEntity = (ctx, pixelsPerUnit, pos, invincibility) ->
    if invincibility > 0
      ctx.fillStyle = '#FFF'
    else
      ctx.fillStyle = '#AEEE00'


    ctx.beginPath()
    radius = 0.01
    ctx.arc(pos.x*pixelsPerUnit, pos.y*pixelsPerUnit, radius*pixelsPerUnit, 0, Math.PI * 2)
    ctx.closePath()
    ctx.fill()
    # ctx.fillRect(pos.x*pixelsPerUnit-sidelength/2,pos.y*pixelsPerUnit-sidelength/2,sidelength,sidelength)

  drawBeat = (ctx, pixelsPerUnit, pos, type) ->
    ctx.fillStyle = typeColors[type]
    ctx.beginPath()
    radius = 0.01
    ctx.arc(pos.x*pixelsPerUnit, pos.y*pixelsPerUnit, radius*pixelsPerUnit, 0, Math.PI * 2)
    ctx.closePath()
    ctx.fill()

  drawTatum = (ctx, pixelsPerUnit, pos, type) ->
    ctx.fillStyle = typeColors[type]
    ctx.beginPath()
    radius = 0.005
    ctx.arc(pos.x*pixelsPerUnit, pos.y*pixelsPerUnit, radius*pixelsPerUnit, 0, Math.PI * 2)
    ctx.closePath()
    ctx.fill()

  drawCenterTatum = (ctx, pixelsPerUnit, radius, pos) ->
    ctx.fillStyle = '#FFF'
    ctx.beginPath()
    ctx.arc(pos.x*pixelsPerUnit, pos.y*pixelsPerUnit, radius*pixelsPerUnit, 0, Math.PI * 2)
    ctx.closePath()
    ctx.fill()

  spiralToCartesian = (spins, spinTheta, center) ->
    x: Math.cos(spins*2*Math.PI - spinTheta) * spins*2*Math.PI * 0.01 + center.x
    y: Math.sin(spins*2*Math.PI - spinTheta) * spins*2*Math.PI * 0.01 + center.y

  circleToCartesian = (time, maxTime, radius, spinTheta, center) ->
    theta = time/maxTime * 2 * Math.PI - Math.PI/2
    {x: Math.cos(theta - spinTheta)*radius + center.x
    y: Math.sin(theta - spinTheta)*radius + center.y}

  audioLoaded = false
  audioPlaying = false
  audioInfo = null
  audioPlayer = null
  guar = (ctx, G, dt) ->
    pixelsPerUnit = G.screenDims.widthPX;
    unless audioLoaded
      audioInfo = STATE.song_analyses.read()
      songIndex = 1
      if audioInfo? and audioInfo.length > songIndex
        chosenSongInfo = audioInfo[songIndex]
        audioPlayer = new Audio(chosenSongInfo.song_info.track_url+'/download')
        G.audio.beats = chosenSongInfo.analysis.beats
        G.audio.bars = chosenSongInfo.analysis.bars
        G.audio.tatums = chosenSongInfo.analysis.tatums
        audioLoaded = true
        audioPlayer.currentTime = G.elapsedTime
        audioPlayer.oncanplay = () ->
          unless audioPlaying
            audioPlayer.play()
            audioPlayer.currentTime = G.elapsedTime
            audioPlaying = true

    # print(audioPlayer.currentTime)

    if audioPlaying
      G = gameplayLoop(ctx, G, dt)
    else
      clearScreen(ctx, G.screenDims,0)
      ctx.textAlign="left";
      ctx.fillStyle = '#000'
      ctx.font="20px Georgia";
      ctx.fillText("Loading...",10,30);

    # ms Counter
    ctx.textAlign="right";
    ctx.fillStyle = '#000'
    ctx.font="20px Georgia";
    ctx.fillText(parseInt(dt*10)/10,pixelsPerUnit * (G.worldDims.width-0.01),30);
    P.swapBuffers()

    G

  beatType = (index) ->
    if index % 3 == 0
      return 1
    return 0

  gameplayLoop = (ctx, G, dt) ->
    pixelsPerUnit = G.screenDims.widthPX;

    center = {
      x: G.worldDims.width/2
      y: G.worldDims.height/2
    }

    if G.didGetHitTimer > 0
      G.didGetHitTimer -= dt
      if G.didGetHitTimer <= 0
        G.elapsedTime -= 1
        audioPlayer.currentTime = G.elapsedTime
        audioPlayer.play()
    else if not G.isPaused
      G.elapsedTime += dt/1000
    # if G.elapsedTime - audioPlayer.currentTime > 0
    #   G.elapsedTime = audioPlayer.currentTime

    if G.input.change
      if G.isPaused
        G.isPaused = false
      else
        G.player.type += 1
        G.player.type = G.player.type % G.player.totalTypes
    # Clear the bg
    clearScreen(ctx, G.screenDims, G.player.type)


    G.audio.beatIndex = 0
    while G.audio.beats.length > G.audio.beatIndex+1 and G.audio.beats[G.audio.beatIndex]? and G.audio.beats[G.audio.beatIndex].start < G.elapsedTime
      # print(G.audio.beats[G.audio.beatIndex])
      G.audio.beatIndex++
    # print(G.audio.beatIndex)

    G.worldRot = G.elapsedTime * 0.1
    G.worldRot = G.worldRot % (2*Math.PI) # Wrap around

    ctx.strokeStyle = '#000'
    ctx.lineWidth = 0.004 * pixelsPerUnit
    ctx.beginPath()
    scaler = 0.02 * Math.sin(G.audio.beats[G.audio.beatIndex].duration - (G.elapsedTime - G.audio.beats[G.audio.beatIndex].start))
    radius = 0.30 + scaler
    ctx.arc(center.x * pixelsPerUnit, center.y * pixelsPerUnit, radius * pixelsPerUnit, 0, 2 * Math.PI)
    x = Math.cos(Math.PI * 2 - Math.PI/2 - G.worldRot)*radius + center.x
    y = Math.sin(Math.PI * 2 - Math.PI/2 - G.worldRot)*radius + center.y
    ctx.moveTo(x * pixelsPerUnit, y * pixelsPerUnit)
    x = Math.cos(Math.PI * 2 - Math.PI/2 - G.worldRot)*radius/2 + center.x
    y = Math.sin(Math.PI * 2 - Math.PI/2 - G.worldRot)*radius/2 + center.y
    ctx.lineTo(x * pixelsPerUnit, y * pixelsPerUnit)
    ctx.stroke()


    tatumIndex = 0
    while G.audio.tatums.length > tatumIndex+1 and G.audio.tatums[tatumIndex]? and G.audio.tatums[tatumIndex].start < G.elapsedTime
      # print(G.audio.beats[G.audio.beatIndex])
      tatumIndex++
    tatumScaler = 0.05 * Math.sin(G.audio.tatums[tatumIndex].duration - (G.elapsedTime - G.audio.tatums[tatumIndex].start))
    tatumRadius = 0.06 + tatumScaler
    drawCenterTatum(ctx, pixelsPerUnit, tatumRadius, center)


    playerPos = circleToCartesian(G.elapsedTime, G.levelTime, radius, G.worldRot, center)

    if G.invincibilityTimer > 0
      G.invincibilityTimer -= dt

    for beat,i in G.audio.beats
      if beat?
        t = beatType(i) #(if beat.confidence > 0.6 then 1 else 0)

        if beat.start < G.levelTime
          pos = circleToCartesian(beat.start, G.levelTime, radius, G.worldRot, center)
          drawBeat(ctx, pixelsPerUnit, pos, t)

          if G.invincibilityTimer <= 0 and Math.abs((G.elapsedTime % G.levelTime) - beat.start) <= G.player.collisionRadius and t != G.player.type
            # print 'die'
            audioPlayer.pause()
            G.invincibilityTimer = (1/60*1000) * 30
            G.didGetHitTimer = (1/60*1000) * 20

        else if beat.start < G.levelTime*2
          pos = circleToCartesian(beat.start, G.levelTime, radius/2, -G.worldRot, center)
          drawBeat(ctx, pixelsPerUnit, pos, t)


    # for tatum in G.audio.tatums
    #   if tatum? and tatum.start < G.levelTime
    #     pos = circleToCartesian(tatum.start, G.levelTime, radius, G.worldRot, center)
    #     t = (if tatum.confidence > 0.6 then 1 else 0)
    #     drawTatum(ctx, pixelsPerUnit, pos, t)

        # if Math.abs((G.elapsedTime % G.levelTime) - beat.start) <= G.player.collisionRadius and t != G.player.type
        #   print 'die'
        #   G.elapsedTime -= 1
        #   audioPlayer.currentTime = G.elapsedTime


    drawEntity(ctx, pixelsPerUnit, playerPos, G.invincibilityTimer)

    # levelTime

    # ctx.beginPath();
    # ctx.moveTo(center.x*pixelsPerUnit, center.y*pixelsPerUnit);
    # ctx.strokeStyle = '#000'
    # ctx.lineWidth = 4
    # spiralRings = 5
    # last = {}
    # for t in [0..spiralRings] by 0.01
    #   {x: x, y: y} = spiralToCartesian(t, G.worldRot, center)
    #   ctx.lineTo(x*pixelsPerUnit, y*pixelsPerUnit)
    # ctx.stroke()

    # v = 2*Math.PI*0.005/4 # speed for approx 10 sec; TODO(JULIAN): Make Exact
    # playerRotSpeed = if G.playerPos.theta<=0 then 0 else v/(2*Math.PI * G.playerPos.theta)

    # beatTime = 0
    # beatRot = 5
    # while beatTime < 2
    #   beatRotSpeed = if beatRot<=0 then 0 else v/(2*Math.PI * beatRot)
    #   drawBeat(ctx, pixelsPerUnit, spiralToCartesian(beatRot, G.worldRot, center))
    #   beatRot -= 16 * beatRotSpeed
    #   beatTime += v


    # console.log(G.playerPos.theta)
    # G.playerPos.theta -= dt * playerRotSpeed
    # G.playerPos.theta = G.playerPos.theta % (2*Math.PI)

    # pos = spiralToCartesian(G.playerPos.theta, G.worldRot, center)
    # drawEntity(ctx, pixelsPerUnit, pos)

    # console.log(G.playerPos.x)

    if G.isPaused
      ctx.textAlign="center";
      ctx.fillStyle = '#000'
      ctx.font="20px Georgia";
      ctx.fillText('[SPACE]',pixelsPerUnit * center.x,pixelsPerUnit * center.y + 5);

    G

  window.requestAnimationFrame step