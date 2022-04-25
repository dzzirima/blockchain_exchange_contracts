pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC20.sol";


contract Exchange is ERC20{
    address public cryptoDevTokenAddress;


    /**The exchane is inheriting the erc20 */

    constructor(address _CryptoDevToken) ERC20("CryprDev LP Token", "CDLP"){
        require(_CryptoDevToken != address(0),"Token address passed is a null address");
        cryptoDevTokenAddress = _CryptoDevToken;
    } 

    /**functions to get the reserves */
    /**
    1.ETh reserver will be equal to the balance of the smart contract  found by address(this).balance
    2.We know the Crypto dev token where we deployed it , so we can just call balanceof
     */

     function getReserve() public view returns (uint) {

         return ERC(cryptoDevTokenAddress).balanceOf(address(this));
     }

     /**function to     add liquidity  */

     function addLiquidity (uint _amount) public payable returns (uint){
         uint liquidity;
         uint ethBalance = address(this).balance;
         uint cryptoDevTokenReserve = getReserve();
         ERC crytoDevToken = ERC(cryptoDevTokenAddress);


         /**if the reserve is empty , take any amount of ether or crptoDev coz there is ratio */
         if(cryptoDevTokenReserve == 0){
             /**
             1.transfer the crytodebv token from the user to our contrct
              */
              crytoDevToken.transferFrom(msg.sender , address(this) , _amount);

              liquidity = ethBalance;
              
              //send the LP token to the user
              _mint(msg.sender ,liquidity);
         }else{
             /**the reserve is not empty , take any amountof ETH and calculate the amount of token which needs to be minted */
             //ge the current amount of ether
             uint ethReserve = ethBalance - msg.value;

             /**we should maintain the ratios to avoid any price spark  */
            // Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract);
            // So doing some maths, (cryptoDevTokenAmount user can add) = (Eth Sent by the user * cryptoDevTokenReserve /Eth Reserve);
            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/ethReserve;

            require(_amount >= cryptoDevTokenAmount ,"Amount of token sent is less than the minimum tokens required");

            cryptoDevToken.transferFrom(msg.sender , address(this), cryptoDevTokenAmount);

            //again the amount of LP send to to the user should be maintained
            liquidity = (totalSupply()*msg.value)/ethReserve;
            _mint(msg.sender,liquidity);
         }
         return liquidity;
     }

     /**funtionn to remove liquidity ie sendiing back the eth to user 
     amount of LP removed will be burnt
     */
     function removeLiquidity(uint _amount ) public returns (uint , uint){
         require(_amount > 0 , "amount should be greater than zero");
         uint ethReserve = address(this).balance;
         uint _totalSupply = totalSupply();

        //The amount of Eth that would be sent back to the user is based on a ratio 
        //Ratio is -> (Eth sent back to the user/ Current Eth reserve)= (amount of LP tokens that user wants to withdraw)/ Total supply of `LP` tokens

        uint ethAmount = (ethReserve * _amount) /_totalSupply ;

        //using  the same formula to calculate the amount of cryptoDev token that will be sent to client
        uint cryptoDevTokenAmount = (getReserve()* _amount)/_totalSupply;

        ///Burning the LP tokens coz we have already sent them back to the user
        _burn(msg.sender , _amount);

        //transfer the eth to the user wallet
        payable(msg.sender).transfer(ethAmount);

        //tranfer the cryptoDevToken from the user to the contract
        ERC20(cryptoDevTokenAddress).transfer(msg.sender,cryptoDevTokenAmount);

        return (ethAmount,cryptoDevTokenAmount);
     }




}