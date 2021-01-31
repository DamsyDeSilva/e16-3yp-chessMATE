// Adapt to the listening port number you want to use
var webSocketsServerPort = 3000; 

// websocket and http servers
var webSocketServer = require('websocket').server;
var http = require('http');

//import mysql
const {createPool} = require('mysql');

const pool = createPool({
    host: "localhost",
    user:"root",
    password:"",
    database:"chessapp_db",
    connectionLimit:10

})

/**
* HTTP server to implement WebSockets
*/
var server = http.createServer(function(request, response) {});

server.listen(webSocketsServerPort, function() {
    console.log((new Date()) + " Server is listening on port "
        + webSocketsServerPort);
  });

/**
* WebSocket server
*/
var wsServer = new webSocketServer({
    // WebSocket server is tied to a HTTP server. WebSocket request is just an enhanced HTTP request. 
    httpServer: server
});

// -----------------------------------------------------------
// List of all players and List of all matches 
// -----------------------------------------------------------
var Players = [];
var Matches = [];

// player detail structure
function Player(id, connection){
    this.id = id;
    this.connection = connection;
    this.name = "";
    this.opponentIndex = null;
    this.index = Players.length;
}

Player.prototype = {
    getId: function(){
        return {name: this.name, id: this.id};
    },
    setOpponent: function(id){
        var self = this;
        Players.forEach(function(player, index){
            if (player.id == id){
                self.opponentIndex = index;
                Players[index].opponentIndex = self.index;
                return false;
            }
        });
    }
};


// Match detail structure
function Match(player_1, player_2, id){
    this.id = id;               // player_1_id;player_2_id
    this.player_1 = player_1;
    this.player_2 = player_2;
    this.is_Stream = false;
    this.viewList = [];
}

Match.prototype = {
    getId: function(){
        return {player_1: this.Player_1.name, player_2: this.Player_2.name, id: this.id};
    },

    addViewers: function(viewer_id){
        var self = this;
        self.viewList.push(viewer_id);
        return false;
    }
};


// This callback function is called every time someone tries to connect to the WebSocket server
wsServer.on('request', function(request) {
    
    var connection = request.accept(null, request.origin); 
    
    // New Player has connected.  So let's record its socket
    var player = new Player(request.key, connection);

    // Add the player to the list of all players
    Players.push(player);

    // We need to return the unique id of that player to the player itself
    connection.sendUTF(JSON.stringify({action: 'connect', data: player.id}));

    // Listen to any message sent by that player
    connection.on('message', function(data) {

        // Process the requested action
        var message = JSON.parse(data.utf8Data);

        switch(message.action){

            //
            // When the user sends the "join" action, he provides a name.
            // Let's record it and as the player has a name,
            //
            case 'join':
                //fetch the username which matches the email address
                var emailAndPassword = message.data.split(':');


                let sqlValidity =  `SELECT Username FROM user WHERE EmailAddress = ? AND Password = ?`;
                pool.query(sqlValidity,emailAndPassword,(err0, results, fields)=>{
                    if(err0){
                        return console.log(err0);
                    }
                    else if(results.length == 0){
                        player.connection.sendUTF(JSON.stringify({'action':'userValidity', data:false}));
                    }
                    else{
                        player.connection.sendUTF(JSON.stringify({'action':'userValidity', data:true}));
                        let sqlGetUsername = `SELECT Username FROM user WHERE EmailAddress = ?`;
                        var usernameFetched;
                        pool.query(sqlGetUsername,emailAndPassword[0],(err1, resultsGetUsername, fields)=>{
                            if(err1){
                                return console.log(err1);
                            }
                            //Username fetched
                            usernameFetched = JSON.stringify(resultsGetUsername[0].Username);
                            player.name = usernameFetched;
                            console.log(player.name);
                            // BroadcastPlayersList();
                            //update player status to online
                            let sqlLogin = `UPDATE user SET Status = ? WHERE Username = ?`;
                            let dataLogin = [1, player.name];
                            pool.query(sqlLogin,dataLogin,(err, resultsLogin, fields)=>{
                                if(err){
                                    return console.log(err);
                                }
                                return console.log(resultsLogin);
                            });
                    
                        });
                    }
                    
                    
                });

            case 'request_players_list':
                request_player_id = player.id;
                var playersList = [];
                Players.forEach(function(player){
                    if (player.id != request_player_id){
                        playersList.push(player.getId());
                    }
                });
            
                player.connection.sendUTF(JSON.stringify({
                    'action': 'players_list',
                    'data': playersList
                }));
                break;
                
            case 'sign_in':
                var dataSignIn = message.data.split(':');
    
                let sqlSignIn = `INSERT INTO user(Username,EmailAddress,Password,DateOfBirth) VALUES(?,?,?,?)`;
                let dataInsert = [dataSignIn[0], dataSignIn[1], dataSignIn[2], dataSignIn[3]];
                pool.query(sqlSignIn,dataInsert,(err, results, fields)=>{
                    if(err){
                        return console.log(err);
                    }
                    return console.log(results);
                });
                break;

            case 'resign':
                console.log('resigned');
                    Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({'action':'resigned'}));

                    setTimeout(function(){
                    Players[player.opponentIndex].opponentIndex = player.opponentIndex = null;
                    }, 0);
                break;

            //
            // A player initiates a new game.
            // Let's create a relationship between the 2 players and
            // notify the other player that a new game starts
            // 
            // then add the match to the matches
            case 'new_game':
                player.setOpponent(message.data);
                Players[player.opponentIndex]
                .connection
                .sendUTF(JSON.stringify({'action':'new_game', 'data': player.name}));

                match_id = (player.id).concat(";").concat(message.data);
                var match = new Match(player.id, message.data, match_id);
                Matches.push(match);
                break;

            //
            // A player sends a move.  Let's forward the move to the other player
            //
            case 'onMove':
                Players[player.opponentIndex]
                .connection
                .sendUTF(JSON.stringify({'action':'onMove', 'data': message.data}));
                break;
                
            // 
            // when a third party player wants to view a streaming game 
            // and the player to the correponding viewList
            //  
            case  'request_to_view':
                viewer_id = player;
                match_id = message.data;
                Matches[match_id].viewList.push(player);
                break;

            //
            // when a player wants to stream the match
            // set the is_Stream  to true of the corresponding match
            // 
            case 'request_to_stream':
                match_id = message.data;
                Matches[match_id].is_Stream = true;
                break;

            // 
            // to get the streaming matches
            // 
            case 'streaming_matches':
                var matchList = [];
                Matches.forEach(function(match){
                    matchList.push(match.getId());
                    
                });
            
                var send_message = JSON.stringify({
                    'action': 'match_list',
                    'data': matchList
                });
                player.connection.sendUTF(send_message)
                break;
        }
    });

    // user disconnected
    connection.on('close', function(connection) {
        // We need to remove the corresponding player
        var index = Players.indexOf(player);
        if (index > -1) {
            Players.splice(index, 1);
        }
    });

});
