pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdSale is Context, Ownable {
  IERC20 _token;
  uint256 _rate;
  address payable _fundAddress;
  uint256 _startTime;
  uint256 _endTime;
  bool _initialized;
  bool _finalized;

  struct PaymentRecord {
    uint256 _amount;
    uint256 _withdrawalTime;
  }

  mapping(address => PaymentRecord) _withdrawalList;
  mapping(address => uint256) _buyRecord;

  modifier notExceed5BNB() {
    require(
      _buyRecord[_msgSender()] <= (5 * 10**18),
      "Crowdsale: You have exceeded the quota"
    );
    _;
  }

  modifier onlyFundAddress() {
    require(
      _msgSender() == _fundAddress,
      "Crowdsale: Only fund address can execute this function"
    );
    _;
  }

  event PaymentMade(address buyer, uint256 amount);
  event RateChanged(uint256 newRate);

  constructor(
    address token_,
    uint256 rate_,
    address fundAddress_
  ) public Ownable() {
    _token = IERC20(token_);
    _rate = rate_;
    _fundAddress = payable(fundAddress_);
  }

  function _incrementRecordAmount(uint256 _amount) private {
    _buyRecord[_msgSender()] = _buyRecord[_msgSender()] + _amount;
  }

  function setRate(uint256 rate_) external onlyFundAddress returns (bool) {
    require(rate_ > 0, "Crowdsale: Rate must be greater than 0");
    _rate = rate_;
    emit RateChanged(rate_);
    return true;
  }
}
