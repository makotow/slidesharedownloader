# SlideShareDownloder

## What is this?

Simple SlideShare downloder with SlideShare API.

## Current features

Currently, this script has simple functions jsut download slides find by slideshare user name.


## Requirements

This simple program using SlideShare API. (see detail forllowing link)

- [SlideShare API Documentation](https://www.slideshare.net/developers/documentation#get_slideshow)

Slideshare API key and secret key can get following apply form.

- [Apply API Key](https://www.slideshare.net/developers/applyforapi)


## How to use?

Set environment variables.

```
export API_KEY=~some_api_key
export SHARED_SECRET=~some_shared_secret
```

direnv is useful to set environment variables.
[direnv](https://github.com/direnv/direnv)


Just run ruby scripts.

```
$ ruby ./dowload.rb SlideShareUserName outpudir
```


## Authors

[@makotow](https://github.com/makotow)

## License

MIT
