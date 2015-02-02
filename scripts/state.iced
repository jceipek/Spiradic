define [], () ->

	read = () ->
	    JSON.parse window.sessionStorage.getItem('gameState')

	set = (gs) ->
	    window.sessionStorage.setItem('gameState', JSON.stringify gs)

	readSongs = () ->
	    JSON.parse window.sessionStorage.getItem('songState')

	setSongs = (ss) ->
	    window.sessionStorage.setItem('songState', JSON.stringify ss)

	readSongAnalyses = () ->
	    JSON.parse window.sessionStorage.getItem('songAnalysis')

	setSongAnalyses = (sa) ->
	    window.sessionStorage.setItem('songAnalysis', JSON.stringify sa)

	return {
			read: read
			set: set
			songs: {
				read: readSongs
				set: setSongs
			}
			song_analyses: {
				read: readSongAnalyses
				set: setSongAnalyses
			}
			}