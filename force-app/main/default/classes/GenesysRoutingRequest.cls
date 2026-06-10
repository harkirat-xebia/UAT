/**
 * Created by noorgoolamnabee on 30/05/2023.
 */

global with sharing class GenesysRoutingRequest {
  //Name of the flow in Genesys
  public String flowId;
  public String fromName;
  public Attributes attributes;

  public GenesysRoutingRequest() {
    this.attributes = new Attributes();
    this.attributes.pref_Agent = '';
    this.attributes.priorite = '';
    this.attributes.pref_Agent_Bkp = '';
    this.attributes.sens = 'Inbound';
    this.attributes.agent_Backup = '';
    this.attributes.email_Subject = '';
    this.attributes.email_Description = '';
    this.attributes.client_Priority = '';
  }

  public class Attributes {
    public String fa_sf;
    public String sf_urlpop;
    public String pref_Agent;
    public String pref_Agent_Bkp;
    public String priorite;
    public String type_activite;
    public String owner_id;
    public String agent_Backup;
    public String email_Subject;
    public String email_Description;
    public String client_Priority;
    public String sens;
  }
}