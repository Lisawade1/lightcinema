// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.4.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.4.2/access/Ownable.sol";

contract Cinema is ERC20, Ownable {
    // ============================================
    // Initial Statements
    // ============================================

    // Constructor
    constructor () ERC20("Movies", "MC") {
        _mint(address(this), 1000);
    }

    // Data structure to store customer data
    struct Customer {
        uint256 tokens_purchased;
        string [] enjoyed_movies;
    }

    // Mapping for customer registration
    mapping (address => Customer) public Customers;

    // ============================================
    // Token Management
    // ============================================

    // Function to set the price of a Token
    function priceTokens(uint256 _numTokens) internal pure returns (uint256){
        return _numTokens * (0.01 ether);
    }

    // Function to view the account token balance
    function balanceTokens(address _acount) public view returns (uint256){
        return balanceOf(_acount);
    }

    // Function to mint more tokens
    function mint(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
    }

    // Function to buy tokens
    function purchaseTokens(uint256 _numTokens) public payable {
        // Set the price of the tokens
        uint256 cost = priceTokens(_numTokens);
        // The money that the customer pays for the tokens is evaluated
        require(msg.value >= cost,
            "Buy less tokens or pay with more ethers.");
        // Obtaining the number of tokens available from the Smart Contract
        uint256 balance = balanceTokens(address(this));
        require(_numTokens <= balance, "Not enough tokens available. Please buy a smaller number of tokens.");
        // The returnValue is defined as what the customer pays minus what the product is worth
        uint256 returnValue = msg.value - cost;
        // The company send the amount of ethers to the customer
        payable(msg.sender).transfer(returnValue);
        // The number of tokens purchased is transferred to the customer
        _transfer(address(this), msg.sender, _numTokens);
        // Registration of purchased tokens
        Customers[msg.sender].tokens_purchased += _numTokens;
    }

    // Function for a customer to exchange tokens for ethers
    function tokensEthers(uint256 _numTokens) public payable {
        // Verify that the number of tokens is correct
        require(_numTokens > 0,
            "You need to input a positive amount of tokens.");
        require(_numTokens <= balanceTokens(msg.sender),
            "You do not have the tokens you wish to return.");
        // Check if contract has enough ether
        require(address(this).balance >= priceTokens(_numTokens), "Contract does not have enough ether");
        // Step-1: Sending tokens to the Smart Contract
        _transfer(msg.sender, address(this), _numTokens);
        // Step-2: Sending ethers to the customer
        payable(msg.sender).transfer(priceTokens(_numTokens));
    }

    // ============================================
    // Company management
    // ============================================

    // Events
    event EnjoyMovie (string, uint256, address);
    event NewMovie(string, uint256);
    event DeleteMovie(string);

    // Data structure for movies
    struct Movie {
        string movie_name;
        uint256 movie_price;
        bool movie_status;
    }

    // Mapping to relate a movie name to a movie data structure
    mapping(string => Movie) public MappingMovies;

    // Array for storing the name of the movies
    string [] Movies;

    // Incorporate new movies into the Cinema
    function newMovie (string memory _movie_name, uint256 _movie_price) public onlyOwner {
        // Check if movie already exists
        require(bytes(MappingMovies[_movie_name].movie_name).length == 0, "Movie with that name already exists");

        // Creation of a new movie for the cinema
        MappingMovies[_movie_name] = Movie(_movie_name, _movie_price, true);
        // Storing the movie name in an array
        Movies.push(_movie_name);
        // Broadcast event for new movie created
        emit NewMovie(_movie_name, _movie_price);
    }

    // Function to remove a movie from the cinema
    function deleteMovie(string memory _movie_name) public onlyOwner {
        // Check if movie exists
        require(bytes(MappingMovies[_movie_name].movie_name).length != 0, "Movie with that name does not exist");

        // Movie status is set to FALSE => Not available in the cinema
        MappingMovies[_movie_name].movie_status = false;
        // Remove movie from list
        _removeMovie(_movie_name);
        // Emission of the event for the elimination of the movie
        emit DeleteMovie(_movie_name);
    }

    // Remove movie from Movies array
    function _removeMovie(string memory _movie_name) private {
        for (uint i = 0; i<Movies.length; i++){
            if(keccak256(bytes(Movies[i])) == keccak256(bytes(_movie_name))) {
                delete Movies[i];
                break;
            }
        }
    }

    // Function to watch a movie and pay tokens for it
    function watchMovie(string memory _movie_name) public {
        // Verify the status of the movie (if it is available for watching)
        require(MappingMovies[_movie_name].movie_status == true,
            "This is not available in this cinema.");
        // Price of the movie (in tokens)
        uint256 movie_tokens = MappingMovies[_movie_name].movie_price;
        // Verify the number of tokens the client has to watch the movie
        require(movie_tokens <= balanceTokens(msg.sender),
            "You need more tokens to watch this movie.");
        _transfer(msg.sender, address(this), movie_tokens);
        // Storage in the client's history of watched movies
        Customers[msg.sender].enjoyed_movies.push(_movie_name);
        // Broadcasting of the event to enjoy the movie
        emit EnjoyMovie(_movie_name, movie_tokens, msg.sender);
    }

    // ============================================
    // Information storage
    // ============================================

    // Function to visualize the movie history
    function movieHistory(address _account) public view returns (string [] memory) {
        return Customers[_account].enjoyed_movies;
    }

    // Function to visualize movies available in the cinema
    function cinemaSchedule() public view returns (string [] memory){
        return Movies;
    }

    // Extraction of ethers from the Smart Contract to the Owner
    function withdraw() external payable onlyOwner{
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

}
