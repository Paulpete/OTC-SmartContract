pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdSale is Context, Ownable {
  /// The Doge2 token
  IERC20 _token;

  /// Rate
  uint256 _rate;

  struct PaymentRecord {
    uint256 _amount;
    uint256 _withdrawalTime;
  }

  /// A map of addresses to amount of tokens that can be withdrawn in a month
  mapping(address => PaymentRecord) _withdrawalList;
  mapping(address => uint256) _buyRecord;

  modifier notExceed5BNB() {
    require(
      _buyRecord[_msgSender()] <= (5 * 10**18),
      "Crowdsale: You have exceeded the quota"
    );
    _;
  }

  constructor(address token_, uint256 rate_) public Ownable() {
    _token = IERC20(token_);
    _rate = rate_;
  }
}
