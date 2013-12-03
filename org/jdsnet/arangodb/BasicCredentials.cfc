/**
 * BasicCredentials
 * 
 * @author jesse.shaffer
 * @date 12/1/13
 **/
component accessors=true output=false persistent=false implements=Credentials {
	property string username default="root";
	property string password default="";
	
	/**
	 * Constructor
	 **/
	public BasicCredentials function init(string username="root", string password="") {
		variables.username = arguments.username;
		variables.password = arguments.password;
		return this;
	}

	/**
	 * Interface method - binds credentials to the request object before sending.
	 **/
	public void function bind(required Http requestObject) {
		requestObject.setUsername(variables.username);
		requestObject.setPassword(variables.password);
	}

	/**
	 * Username setter
	 **/
	public void function setUsername(required string username) {
		variables.username = arguments.username;
	}

	/**
	 * Password setter
	 **/
	public void function setPassword(required string password) {
		variables.password = arguments.password;
	}

	/**
	 * Username getter
	 **/
	public string function getUsername() {
		return variables.username;
	}

	/**
	 * Password getter
	 **/
	public string function getPassword() {
		return variables.password;
	}

}