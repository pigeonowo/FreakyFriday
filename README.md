# FreakyFriday

Jam out with your colleagues to all kinds of Songs.
Each user has a limited number of actions. Make sure to skip the song you hate the most.

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
This program uses the Spotify API. (Details under Development)

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
