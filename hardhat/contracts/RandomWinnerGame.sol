//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//Import statements
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {
    //initializing the varibles of the VRFConsumerBase
    uint256 public fee;
    bytes32 public keyHash;

    //initializing the variables for our contract
    uint8 maxPlayers; //max number of players in one game
    address[] public players; //address of the players
    uint256 entryFee; //fees for entering the game
    bool public gameStarted; //indicates if the game has started or not
    uint256 public gameId; //id of the current game

    //events to emit
    //when the game starts
    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    //When the player comes
    event PlayerJoined(uint256 gameId, address player);
    //when the game ends
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    //constructors that inherits from the vrfConsumerBase
    constructor(
        address vrfCoordinator,
        address linktoken,
        bytes32 vrfKeyHash,
        uint256 vrfFee
    ) VRFConsumerBase(vrfCoordinator, linktoken) {
        fee = vrfFee;
        keyHash = vrfKeyHash;
        gameStarted = false;
    }

    //function that the owner can call to  start the game
    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!gameStarted, "Game is currently running!");
        delete players; //array of players is being emptied
        maxPlayers = _maxPlayers;
        entryFee = _entryFee;
        gameStarted = true;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);
    }

    //joinGame is  being called when a player wants to join the game
    function joinGame() public payable {
        require(gameStarted, "Game is not bieng started yet!");
        require(
            msg.value == entryFee,
            "Value sent is not equal to the entry fee"
        );
        require(players.length < maxPlayers, "Game is full");
        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);
        //if the list is full then start the winner selection process
        if(players.length==maxPlayers){
            getRandomWinner();
        }
    }

    //fulfillRandomness is overirdden from the VRFConsumerBase 
    function fulfillRandomness(bytes32 requestId,uint256 randomness) internal virtual override{
        //we want our winnerIndex to lie between 0 to players.length-1;
        uint256 winnerIndex=randomness%players.length;
        address winner = players[winnerIndex];
        //sending the money to the winner
        (bool sent,)=winner.call{value:address(this).balance}("");
        require(sent,"Failed to send the ether!");
        //Emitting that the game has ended
        emit GameEnded(gameId,winner,requestId);
        gameStarted=false;

    }

    //getRandomWinner() is called to start the process of random winner selection
    function getRandomWinner() private returns(bytes32 requestId){
        // LINK is an internal interface for Link token found within the VRFConsumerBase
        // Here we use the balanceOF method from that interface to make sure that our
        // contract has enough link so that we can request the VRFCoordinator for randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash,fee);
    }

    //Function to recieve ether. msg.data must be empty
    receive() external payable {}
    //Fallback function called when the msg.data is not empty
    fallback() external payable {}
}
