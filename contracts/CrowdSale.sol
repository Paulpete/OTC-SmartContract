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
  event CrowdSaleBegun(uint256 startTime, uint256 endTime);
  event CrowdSaleExtended(uint256 newEndTime);
  event CrowdSaleFinalized(uint256 timestamp);
  event WhiteListedForWithdrawal(address account);
  event TokenSold(address recipient, uint256 amount);

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

  function beginCrowdSale(uint256 _days)
    external
    onlyFundAddress
    returns (bool)
  {
    require(!_initialized, "Crowdsale: Sale has already begun");
    require(!_finalized, "Crowdsale: Sale already finalized");
    _startTime = block.timestamp;
    _endTime = block.timestamp + (_days * 1 days);
    _initialized = true;
    emit CrowdSaleBegun(_startTime, _endTime);
    return true;
  }

  function extendCrowdSale(uint256 _days)
    external
    onlyFundAddress
    returns (bool)
  {
    require(!_finalized, "CrowdSale: Sale already finalized");
    _endTime = _endTime + (_days * 1 days);
    emit CrowdSaleExtended(_endTime);
    return true;
  }

  function _transferRemainingTokens() private returns (bool) {
    return _token.transfer(_fundAddress, _token.balanceOf(address(this)));
  }

  function finalizeCrowdSale() external onlyFundAddress returns (bool) {
    require(!_finalized, "CrowdSale: Sale cannot be finalized twice");
    require(
      _transferRemainingTokens(),
      "CrowdSale: Could not transfer remaining tokens"
    );
    _finalized = true;
    emit CrowdSaleFinalized(block.timestamp);
    return true;
  }

  function getRemainingDays() public view returns (uint256) {
    if (_finalized) return 0;

    uint256 currentTimestamp = block.timestamp;

    if (_endTime > currentTimestamp) return _endTime - currentTimestamp;

    return 0;
  }

  function buyWithImmediateWithdrawal() public payable notExceed5BNB {
    require(block.timestamp >= _startTime, "CrowdSale: Sale has not begun yet");
    require(block.timestamp < _endTime, "CrowdSale: Sale has ended");
    require(!_finalized, "CrowdSale: Sale has been finalized");

    uint256 _valueAsWei = msg.value * 10**18;
    uint256 _valueDividedByRate = _valueAsWei / _rate;
    uint256 _25Percent = (_valueDividedByRate * 25) / 100;

    require(
      _token.balanceOf(address(this)) >= _25Percent,
      "CrowdSale: Not enough tokens to sell"
    );
    bool _sold = _token.transfer(_msgSender(), _25Percent);

    require(_sold, "CrowdSale: Failed to transfer tokens");

    _incrementRecordAmount(_valueAsWei);

    emit TokenSold(_msgSender(), _25Percent);
  }

  function buyWithLateWithdrawal() public payable notExceed5BNB {
    require(block.timestamp >= _startTime, "CrowdSale: Sale has not begun yet");
    require(block.timestamp < _endTime, "CrowdSale: Sale has ended");
    require(!_finalized, "CrowdSale: Sale has been finalized");

    uint256 _valueAsWei = msg.value * 10**18;
    uint256 _valueDividedByRate = _valueAsWei / _rate;

    require(
      _token.balanceOf(address(this)) >= _valueDividedByRate,
      "CrowdSale: Not enough tokens to sell"
    );

    PaymentRecord storage _paymentRecord = _withdrawalList[_msgSender()];
    _paymentRecord._amount = _paymentRecord._amount + _valueDividedByRate;

    if (_paymentRecord._withdrawalTime == 0) {
      _paymentRecord._withdrawalTime = block.timestamp + (30 * 1 days);
    }

    _incrementRecordAmount(_valueAsWei);
    emit WhiteListedForWithdrawal(_msgSender());
  }

  function withdraw() external returns (bool) {
    require(
      _withdrawalList[_msgSender()]._withdrawalTime <= block.timestamp,
      "CrowdSale: Can only withdraw in 30 days from purchase request"
    );
    require(
      _token.transfer(_msgSender(), _withdrawalList[_msgSender()]._amount),
      "CrowdSale: Could not withdraw tokens"
    );
    emit TokenSold(_msgSender(), _withdrawalList[_msgSender()]._amount);
  }

  function tokensToBeReceived(uint256 _amount) public returns (uint256) {
    uint256 _tbr = (_amount * (_amount / _rate)) / rate;
    return _tbr * 10**18;
  }
}
