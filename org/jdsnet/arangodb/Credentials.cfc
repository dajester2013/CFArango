/**
 * Credentials
 * 
 * @author jesse.shaffer
 * @date 12/1/13
 **/
interface {
	
	public string function getUsername();
	public string function getPassword();
	
	public void function bind(required Http requestObject);
	
}