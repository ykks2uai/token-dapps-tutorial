pragma solidity^ 0.4.24;

/**
 * 2. Implementation of a token smart contract 
 *   12. Let people buy your token
 *     - payable function
 *     - fallback function
 *     - msg.value
 *     - modifier
 */

/**
 * Overflow / Underflow safe math
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Overflow");
        return c;
    }
}

/**
 * Actual ERC20 that can be distributed.
 * It must implement all the ERC20Interface.
 */
contract ERC20Token {
    // Add SafeMath functions to uint256.
    using SafeMath for uint256;

    /**
     * Modifiers in Solidity can be added to any functions.
     * They are executed before or after the function call.
     */
    modifier privileged () {
        // Check the permision.
        require(msg.sender == privilegedAccount, "You are not allowed to call the function.");

        // This magic _ is the actual function call.
        _;
    }

    /**
     * Token name
     */
    string public name;

    /**
     * Token symbol like BTC, ETH and so on.
     */
    string public symbol;

    /**
     * How many digits next to '.'
     * If decimals is 0, 1000 token is displayed as 1000.
     * If 3, 1000 token is displayed as 1.000.
     * Use 18, same decimals as ETH, if you don't have a paticular reason.
     */
    uint8 public decimals;

    /**
     * Exchange rate of eth to the token.
     * Represented as Permyriad 'cause Ethreum cannot store a decimal such as 0.5
     */
    uint32 public exchangeRate;

    /**
     * Privileged account
     */
    address public privilegedAccount;

    /**
     * Maps owner address to his balance
     */
    mapping(address => uint256) private balances;

    /**
     * Maps owner address to spender to be allowed and amount. 
     */
    mapping(address => mapping(address => uint256)) private allowed;

    /**
     * How much token you wait to create.
     */
    uint256 private totalSupply_;

    /**
     * Emitted when the ownership of token is transfered.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Emitted when allowed to spend.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * constructor is a special function that is called to deploy the contract.
     * And it can be called only once when the contract is deployed.
     */
    constructor (string _name, string _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _initialSupply;

        // Transfer 20% to you.
        uint256 toPrivileged = (totalSupply_ / 10).mul(2);
        balances[msg.sender] = toPrivileged;
        balances[this] = totalSupply_ - toPrivileged;

        // The privileged account = You
        privilegedAccount = msg.sender;

        // 10000 means eth : token = 1 : 1 (10000 / 10000 = 1)
        exchangeRate = 10000;
    }

    /**
     * Fallback function is the anonymous function.
     * Executed when you send eth to the contract.
     * A function with the payable modifier is called with eth.
     */
    function () public payable {
        // Tokens should be sent.
        uint256 tokenAmount = msg.value.mul(exchangeRate / 10000);

        // Ensure the balance is enough.
        require(balances[this] >= tokenAmount, "Sorry, we don't have enough balance.");

        balances[this] = balances[this].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        emit Transfer(this, msg.sender, tokenAmount);
    }

    /**
     * Withdraw the whole Eth the contract holds.
     */
    function withdraw () public privileged {
        require(address(this).balance > 0, "Balance is 0.");

        // This is how an account sends Eth (not token) to another.
        msg.sender.transfer(address(this).balance);
    }

    /**
     * Required for ERC20.
     * See _totalSupply for understanding what it stands for.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * Required for ERC20.
     * Get the current balance of `owner`.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    /**
     * Required for ERC20.
     * Transfers token in the amount of `value` from "me"(`msg.sender`) to address `to`.
     * `msg.sender` is the caller of a function.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "You don't have enough balance to transfer.");
        require(to != address(0), "You can't to transfer to 0x0. Please specify the recipient address `to`.");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * Requried for ERC20.
     * Get how many tokens to be allowed to be spend.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * Required for ERC20.
     * Allow spender to spend "my" tokens.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * Required for ERC20.
     * Transfer tokens from one address to another.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "`from`'s balance is insufficient.");
        require(value <= allowed[from][msg.sender], "You're not allowed to spend `from`'s token.");
        require(to != address(0), "`to` address is empty.");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
}
