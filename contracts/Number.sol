pragma solidity ^0.4.11;

// Create a casino like application where users are able to bet money for a number between 1 and 10 and if they’re correct, they win a portion of all the ether money staked after 100 bets.
contract Number {
   address public owner;
   uint256 public minimumBet;
   uint256 public totalBet;
   uint256 public numberOfBets;
   uint256 public maxAmountOfBets = 10;
   address[] public players; // integer-indexed array of players 
   mapping(address => uint256) public amountBet; // mapping of players to how much they bet
   mapping(uint => address[]) public playersWhoBetNumber; // The players who bet this number

   event Bet(address from, uint256 numberSelected);
   event WinnerAnnounced(address winner, uint256 luckyNumber);

   struct Player {
      uint256 amountBet;
      uint256 numberSelected;
   }

   function Number(uint256 _minimumBet, uint _maxAmountOfBets) public {
      // address of user who created contract is owner
      owner = msg.sender;
      if(_minimumBet != 0 ) minimumBet = _minimumBet;
      if(_maxAmountOfBets != 0 ) maxAmountOfBets = _maxAmountOfBets;
   }

   // Only the owner can destroy the contract and remaining ether will be sent to the owner's address
   // Only use as a fallback 
   function kill() public {
      if(msg.sender == owner) selfdestruct(owner);
   }

   // Check if the player has bet already
   // The constant keyword indicates that this function does not cost gas to execute because it returns an existing value from the blockchain
   function checkPlayerExists(address player) public constant returns(bool){
      for(uint256 i = 0; i < players.length; i++){
         if(players[i] == player) return true;
      }
      return false;
   }

   // To bet for a number between 1 and 10 both inclusive
   // Note that the 'payable' modifier indicates that this function can send ether when executed
   function bet(uint256 numberSelected) public payable {
      // If require(some_condition) == false then the function stops and ether is sent returned to sender
      // msg.sender and msg.value are implicitly defined by the user (address and ether amount, respectively) when function is executed
      require(numberSelected >= 1 && numberSelected <= 10);
      require(msg.value >= minimumBet);
      numberOfBets++;

      // add player to sender only if new player to avoid potential sybil attack
      if (!checkPlayerExists(msg.sender)) {
      	players.push(msg.sender);
      	amountBet[msg.sender] = 0;
      }

      amountBet[msg.sender] += msg.value;
      playersWhoBetNumber[numberSelected].push(msg.sender);
      totalBet += msg.value;
      emit Bet(msg.sender, numberSelected);
      if(numberOfBets >= maxAmountOfBets) generateNumberWinner();
   }

  // Generates a number between 1 and 10 that will be the winner
   function generateNumberWinner() public {
      uint256 numberGenerated = uint(keccak256(block.timestamp))%10 +1; // This isn't secure but OK if in testing environment
      distributePrizes(numberGenerated);
   }

   // Reset game settings
   function resetGame() public {
   	  // Delete all the players for each number
      for(uint i = 1; i <= 10; i++){
         playersWhoBetNumber[i].length = 0;
      }

      // Clear out amountBet array
      for (uint j = 0; j < players.length; j++) {
      	amountBet[players[j]] = 0;
      }

      players.length = 0;
      totalBet = 0;
      numberOfBets = 0;
   }

   // Sends the corresponding ether to each winner depending on the total bets
   function distributePrizes(uint256 numberWinner) public {
      
   	  // If no winner, return players their money
   	  if (playersWhoBetNumber[numberWinner].length == 0) {
   	  	for (uint i = 0; i < players.length; i++) {
   	  		players[i].transfer(amountBet[players[i]]);
   	  	}
   	  	resetGame();
   	  	return;
   	  }

      uint prize = totalBet/playersWhoBetNumber[numberWinner].length;
      // Loop through all the winners to send the corresponding prize for each one
      for(uint j = 0; j < playersWhoBetNumber[numberWinner].length; j++){
         playersWhoBetNumber[numberWinner][j].transfer(prize);
         emit WinnerAnnounced(playersWhoBetNumber[numberWinner][j], numberWinner);
      }

      resetGame();
   }

   // Fallback function in case someone sends ether to the contract so it doesn't get lost and to increase the treasury of this contract that will be distributed in each game
   function() public payable {}
}