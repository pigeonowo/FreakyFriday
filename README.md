# FreakyFriday

Jam out with your colleagues to all kinds of Songs.
Each user has a limited number of actions. Make sure to skip the song you hate the most.
![freaky_friday_screenshot](/docs/freaky_friday.png)
## Features
- 1 room to host your party
- 1 host who plays the music
- view the currently playing song via the Spotify API
- guests can join without creating an account
- guests can skip 2 times in a session

## Problems, Future Ideas and Changes
This application currently uses German as the display language because I developed it for my own office. There should be translation in the future.
For the same reason, there only exists 1 room and guests can join without creating an account. You start up the application, jam and get on with your life.
Currently the spotify api callbacks only work for localhost. That means that only the one who starts the application can join as the host.
If I want to expand the application for wider use or make it public, I should make sure that the app is safe to use for a user. Currently the app us just designed for personal use and people who you trust.
### Feature Roadmap
- song voting
  - during the session you can vote songs
  - display the most liked song during the session
- public usage
  - multiple rooms (password)
  - proper account handling
## Spotify API
This program uses the Spotify API. (Details under [Development](#Spotify API integration))

The user who joins as the host is asked to authenticate with Spotify and agree that the app can modify your player (skip songs).
The access token is stored in the cache and whenever a user wants to skip or get the currently playing song, the program uses that access token.
## Up and Running
What you need:
- You will need to create a spotify app under: https://developer.spotify.com/
- Set the client id and secret in your environment variables (SPOTIFY_API_CLIENT_ID, SPOTIFY_API_CLIENT_SECRET)
- Have Elixir version ~> 1.15 and Pheonix version ~> 1.8.1 installed

Clone the repo and run `iex -S mix phx.server` to start the server.
Then you can visit http://localhost:4000/ and join as the host.
You will be redirected to the authentication page.
Your coworkers can then go to http://<yourpcname>:4000/ and join as a guest.
Enjoy the jam!
## Development
> Here is some information about navigating the project.

This is an elixir + pheonix project.
Under `/lib/freaky_friday` you will find all the business logic.
In `/lib/freaky_friday_web` you can find the controllers and liveview page.
### Controllers
There are 2 controllers in this project. `page_controller.ex` and `spotify_api_controller.ex`.
The `page_controller` is there to handle the start page and the `spotify_api_controller` handles authenticating with spotify when you press "join as host".
It sets the access token in the cache that [Room](#Room) uses.
### Spotify API integration
In `/lib/freaky_friday/spotify_api.ex` you can find various functions and constants for integrating the Spotify API.
Important functions are:
- redirect_to_spotify_login
- get_access_token!
- get_current_song!
- skip!
### Room
The room (GenServer defined in `/lib/freaky_friday/room.ex`) is there to hold all the state about the users.
It handles events like join, leave and skip. It uses the cache to get the access token and skip the current song.
It also keeps track of who has how many skips remaining.
### Main (Liveview) Page
This is the page where you can see the current song, all the users and skip.
This liveview page works like the following:
- it periodically queues the currently playing song for display
- handles when a user presses "skip" (`Room.skip`)
- uses a PubSub system to broadcast events like: skip and users joining/leaving
