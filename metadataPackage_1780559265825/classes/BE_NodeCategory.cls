/**Use to create the structure of the tree
* The Node categories are stock in a list.
* Each Node can have a name and can have a list (or not)
* If a list exist, use it to continue the tree with the children
* If the list is null, the tree is over for this part
*/
public with sharing class BE_NodeCategory {
	public String name {get; set;}
	public List<BE_NodeCategory> children {get; set;}

	public BE_NodeCategory(String name, List<BE_NodeCategory> children){
		this.name = name;
		this.children = children;
	}

	public Boolean addInNode(String name, BE_NodeCategory ncToAdd){
		if(this.name.equals(name)){
			this.children.add(ncToAdd);
			return true;
		}
		else{
			for(BE_NodeCategory nc : children){
				if(nc.addInNode(name, ncToAdd)){
					return true;
					break;
				}
			}
			return false;
		}
	}
}