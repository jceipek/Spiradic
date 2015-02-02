# Spiradic

The experience goal of Spiradic is to make players feel rhythmic and frantic in the style of games like Super Hexagon.

##[PLAY](http://jceipek.com/Spiradic/)

(just press space :) )

## DEVELOPMENT
Generate JavaScript files and SourceMaps in the `javascripts` folder from the `scripts` folder every time you save the `.iced` files:

```
iced --watch --runtime window --map -o javascripts/ -c scripts/*
```

Run a simple HTTP server:

```
python -m SimpleHTTPServer
```

or (if you like `node` better than `python`):

```
npm install http-server -g
http-server -p 8000
```

Navigate to `localhost:8000` in your web browser.

### LIVE RELOAD

There are other ways to set this up ([this](https://github.com/guard/guard-livereload) might be a good, free choice), but I used [LiveReload2](http://livereload.com/) with the [browser extension](http://feedback.livereload.com/knowledgebase/articles/86242-how-do-i-install-and-use-the-browser-extensions-). Unfortunately, I couldn't get LiveReload's compiler to generate SourceMaps that Chrome could understand. If you can, you don't even need to run `iced`.


## NEW THINGS
While making this, I learned

- [IcedCoffeeScript](http://maxtaco.github.io/coffee-script/), a programming language that extends [CoffeeScript](http://coffeescript.org/) with async control flow keywords [(await and defer)](http://maxtaco.github.io/coffee-script/#iced_control)
- How to use the [EchoNest](http://the.echonest.com) and [Free Music Archive](http://freemusicarchive.org/api) APIs to find, analyze, and play music.
- How to set up a 'live' game engine that updates whenever code changes and can optionally preserve game state between reloads. My implementation is inspired by Casey Muratori's [Instantaneous Live Code Editing](https://www.youtube.com/watch?v=oijEnriqqcs) for [Handmade Hero](http://handmadehero.org/). I used [`sessionStorage`](https://developer.mozilla.org/en-US/docs/Web/API/Window.sessionStorage) as a quick and dirty alternative to dll loading. I save and load all game state every frame, which probably won't work for large games, but I haven't had any problems with it so far.


## 3rd PARTY LIBRARIES
- [jQuery](http://jquery.com/) (MIT License)
- [requireJS](http://jquery.com/) (MIT License)

## APIs
- [EchoNest](http://developer.echonest.com/docs/v4)
- [Free Music Archive](http://freemusicarchive.org/api)