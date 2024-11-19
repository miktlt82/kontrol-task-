pragma solidity ^0.8.0;

contract ClickerGame {
    struct User {
        string name;
        uint256 balance;
        uint256 clicks;
        uint256 clickMultiplier;
        uint256 withdrawableAmount;
        uint256 lastClickTime;
        bool isRegistered;
    }

    mapping(address => User) public users;
    address public admin;
    uint256 public totalClicks;
    uint256 public registeredUsers;

    event UserRegistered(address indexed user, string name);
    event Clicked(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event UpgradePurchased(address indexed user, uint256 newMultiplier);
    event TokensWithdrawn(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }

    modifier cooldownCheck() {
        require(block.timestamp >= users[msg.sender].lastClickTime + 10 seconds, "Cooldown period ");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(string memory name, address referrer) external {
        require(!users[msg.sender].isRegistered, "User not registered");

        users[msg.sender] = User({
            name: name,
            balance: 0,
            clicks: 0,
            clickMultiplier: 1,
            withdrawableAmount: 0,
            lastClickTime: block.timestamp,
            isRegistered: true
        });

        registeredUsers++;

        if (referrer != address(0) && users[referrer].isRegistered) {
            users[referrer].balance += 500; 
        }

        emit UserRegistered(msg.sender, name);
    }

    function click() external onlyRegistered cooldownCheck {
        User storage user = users[msg.sender];
        
        user.clicks += 1;

        if (block.timestamp >= user.lastClickTime + 10 seconds) {
            user.balance += user.clickMultiplier;
            user.lastClickTime = block.timestamp;
            emit Clicked(msg.sender, user.clickMultiplier);
        } else {
            user.balance += user.clickMultiplier * 2; 
            emit Clicked(msg.sender, user.clickMultiplier * 2);
        }
        
        totalClicks++;
    }

    function transfer(address recipient, uint256 amount) external onlyRegistered {
        require(users[msg.sender].balance >= amount, "Insufficient balance");

        
        users[msg.sender].balance -= amount;

        
        if (!users[recipient].isRegistered) {
            users[recipient].withdrawableAmount += amount; 
        } else {
            users[recipient].balance += amount;
        }

        emit Transferred(msg.sender, recipient, amount);
    }

    function purchaseUpgrade() external onlyRegistered {
        User storage user = users[msg.sender];
        
        require(user.balance >= (totalClicks / registeredUsers), "Not enough balance");

       
        user.balance -= (totalClicks / registeredUsers);
        user.clickMultiplier += 1;

        emit UpgradePurchased(msg.sender, user.clickMultiplier);
    }

    function adminWithdraw(address userAddress, uint256 amount) external onlyAdmin {
        User storage user = users[userAddress];
        
        require(user.balance >= amount, "User balance insufficient ");
                    user.balance -= amount; 
        emit TokensWithdrawn(userAddress, amount);
    }
}
