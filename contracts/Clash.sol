// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Clash {
    enum Move {
        Unrevealed,
        Rock,
        Paper,
        Scissors
    }

    struct Game {
        uint128 gameId;
        address creator;
        bytes32 commitment;
        address[] opponents;
        mapping (address => Move) opponentMoves;
        bool revealed;
        Move move;
    }

    event GameCreated(uint128 gameId, address creator);
    event GamePlayed(uint128 gameId, address player, Move move);

    mapping(uint256 => Game) public games;

    function createCommitment(Move move, uint256 secret) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(move, secret));
    }

    function generateGameId(bytes32 commitment) public pure returns (uint128) {
        bytes32 fullHash = keccak256(abi.encodePacked(commitment));
        return uint128(bytes16(fullHash));
    }

    function createGame(bytes32 commitment) public {
        uint128 gameId = generateGameId(commitment);
        Game storage game = games[gameId];

        require(game.gameId == 0, "Game exists");

        game.gameId = gameId;
        game.creator = msg.sender;
        game.commitment = commitment;
        game.revealed = false;
        game.move = Move.Unrevealed;

        emit GameCreated(gameId, msg.sender);
    }

    function play(uint128 gameId, Move move) public {
        Game storage game = games[gameId];

        address opponent = msg.sender;
        require(opponent != game.creator, "You cannot play against yourself!");

        game.opponents.push(opponent);
        game.opponentMoves[opponent] = move;

        emit GamePlayed(gameId, opponent, move);
    }

    function reveal(uint128 gameId, Move move, uint256 secret) public {
        Game storage game = games[gameId];
        bytes32 claimedCommitment = keccak256(abi.encodePacked(move, secret));
        
        require (claimedCommitment == game.commitment, "Invalid Commitment");
        
        game.move = move;
        game.revealed = true;
    }

    function isPlayerWin(Move playerMove, Move opponentMove) internal pure returns (bool) {
        if (playerMove == Move.Rock && opponentMove == Move.Scissors) {
            return true;
        }
        
        if (playerMove == Move.Scissors && opponentMove == Move.Paper) {
            return true;
        }
        
        if (playerMove == Move.Paper && opponentMove == Move.Rock) {
            return true;
        }

        return false;
    }

    function getGameResults(uint128 gameId) public view returns (address[] memory, bool[] memory) {
        Game storage game = games[gameId];
        
        address[] memory opponents = new address[](game.opponents.length);
        bool[] memory playerWins = new bool[](game.opponents.length);

        Move playerMove = game.move;
        
        for (uint256 i = 0; i < opponents.length; i++) {
            address opponent = game.opponents[i];
            bool playerWon = isPlayerWin(playerMove, game.opponentMoves[opponent]);
            
            opponents[i] = opponent;
            playerWins[i] = playerWon;
        }

        return (opponents, playerWins);
    }
}