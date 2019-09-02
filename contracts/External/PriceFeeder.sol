/**
* MIT License
*
* Copyright (c) 2019 Finocial
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

pragma solidity >= 0.5.0 < 0.6.0;

import "./provableAPI.sol";

/**
*This contract gets the price from Given URL , and transform the price and sends its back to asking method
*Now we are using this contract when a collateral is claimed or sold, so its sold at the current price retrieved from
* market.
*/


contract PriceFeeder is usingProvable {

  string public price;

  event LogNewProvableQuery(string description);
  event LogNewPrice(string price);



  function __callback(
      bytes32 _myid,
      string memory _result,
      bytes memory _proof
  )
      public
  {
      //require(msg.sender == provable_cbAddress(), "Sufficient funds not transferred");
      //update(); // Recursively update the price stored in the contract...
      price = _result;
      emit LogNewPrice(price);
  }

  function update(string memory _contractAddress)
      public
      payable
  {
      if (provable_getPrice("URL") > address(this).balance) {
          emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
      } else {
          emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
          string memory url = strConcat("json(https://api.coingecko.com/api/v3/coins/ethereum/contract/", _contractAddress, ").market_data.current_price.usd");
          provable_query("URL",url);
      }
  }
}
