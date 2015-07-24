# This is a simple example of how to use the slack-client module in CoffeeScript. It creates a
# bot that responds to all messages in all channels it is in with a reversed
# string of the text received.
#
# To run, copy your token below, then, from the project root directory:
#
# To run the script directly
#    npm install
#    node_modules/coffee-script/bin/coffee examples/simple_reverse.coffee
#
# If you want to look at / run / modify the compiled javascript
#    npm install
#    node_modules/coffee-script/bin/coffee -c examples/simple_reverse.coffee
#    cd examples
#    node simple_reverse.js
#

Slack = require '..' #this grabs node-slack-client

token = 'xoxb-YOUR-TOKEN-HERE' # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true
autoMark = true

slack = new Slack(token, autoReconnect, autoMark)

# container for previous songs played
songHistory = []

pauseFlag = true

# flirty messages for flackbot to try and woo slackbot with
flirtyMessages = [
  "I love the way your voice sounds, Slackbot"
  "What a dreambot :hearteyes:"
]

class Song
  constructor: (@url) ->
    #!!! Break apart URL
    #!!! Is it Youtube?
    #!!! Is it SoundCloud?
    ###
      <script src="//connect.soundcloud.com/sdk-2.0.0.js"></script>
      <script>
      SC.initialize({
        client_id: 'YOUR_CLIENT_ID'
      });

      // stream track id 293
      SC.stream("/tracks/293", function(sound){
        sound.play();
      });
      </script>
    ###
    #!!! Is it 8Tracks?
    #!!! Is it Spotify?
  toString: () ->

  query: () ->

playLoop: () ->
  setInterval(playLoop, 1000)
  if not pauseFlag
    # if song is over
      if songHistory.length is not 0
        currentSong = songHistory.shift()

        # play currentSong

        response = "now playing: /n " + currentSong.toString()
        channel.send response
        console.log """
          @#{slack.self.name} responded with "#{response}"
        """
      # transition in song
    # else if song is ending
      # transition out song
    # else
      # play stream
  # else
    # don't play stream


slack.on 'open', ->
  channels = []
  groups = []
  unreads = slack.getUnreadCount()

  # Get all the channels that bot is a member of
  channels = ("##{channel.name}" for id, channel of slack.channels when channel.is_member)

  # Get all groups that are open and not archived
  groups = (group.name for id, group of slack.groups when group.is_open and not group.is_archived)

  console.log "Welcome to Slack. You are @#{slack.self.name} of #{slack.team.name}"
  console.log 'You are in: ' + channels.join(', ')
  console.log 'As well as: ' + groups.join(', ')

  messages = if unreads is 1 then 'message' else 'messages'

  console.log "You have #{unreads} unread #{messages}"

  setInterval(playLoop(), 1000)

slack.on 'message', (message) ->
  channel = slack.getChannelGroupOrDMByID(message.channel)
  user = slack.getUserByID(message.user)
  response = ''

  {type, ts, text} = message

  channelName = if channel?.is_channel then '#' else ''
  channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

  userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

  console.log """
    Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
  """

  if type is 'message' and text? and channel?
    #Check to see who it is from
    # if slackbot
    if userName is 'slackbot'
      response = flirtyMessages[Math.floor(Math.random() * flirtyMessages.length)]

      channel.send response
      console.log """
        @#{slack.self.name} responded with "#{response}"
      """
    # if user
    else if message[0] is '!'
      [command, ..., arguments] = message.split(' ')

      switch command
        #!! if add
        when '!add' then
          try
            newSong = new Song(arguments)
            songHistory.push newSong

            response = "I added a song on queue ;) /n " + newSong.toString() + " /n The position in the queue is: " + songHistory.length
            channel.send response
            console.log """
              @#{slack.self.name} responded with "#{response}"
            """
          catch(_error)
            response = "I am sorry, I could not add that song. /n The error code I am getting is: " + _error
            channel.send response
            console.log """
              @#{slack.self.name} responded with "#{response}"
            """

        #!! if history
        when '!history' then
          #!!! Grab past three songs from song queue
          songsToReturn = if songHistory.length <= 2 then songHistory else songHistory[-2, ..]
          response = ['previous songs played: \n']

          response.push(aSong.toString() + '\n') for aSong in songsToReturn

          channel.send response
          console.log """
            @#{slack.self.name} responded with "#{response}"
          """
        #!! if pause
        when '!pause' then

        #!! if resume
        when '!resume' then

        #!! if not found
        else
          response = "I don't think that was a proper command..."

          channel.send response
          console.log """
            @#{slack.self.name} responded with "#{response}"
          """

  else
    #this one should probably be impossible, since we're in slack.on 'message'
    typeError = if type isnt 'message' then "unexpected type #{type}." else null
    #Can happen on delete/edit/a few other events
    textError = if not text? then 'text was undefined.' else null
    #In theory some events could happen with no channel
    channelError = if not channel? then 'channel was undefined.' else null

    #Space delimited string of my errors
    errors = [typeError, textError, channelError].filter((element) -> element isnt null).join ' '

    console.log """
      @#{slack.self.name} could not respond. #{errors}
    """

slack.on 'error', (error) ->
  console.error "Error: #{error}"

slack.login()
