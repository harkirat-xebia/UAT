public class EmbeddedSigningController {
	
    @AuraEnabled
	public static String sendEnvelope(String template, String description, Id recordId) {
        Id mySourceId = recordId; // The ID of the initiating Salesforce object
        // Create an empty envelope and add a Salesforce Document and embedded signer  recipient
        // The embedded signer will be the current user with sequence and routing order 1 and role "Signer 1" by default

		// Create signer
            // dfsle.Recipient signer = dfsle.Recipient.newEmbeddedSigner();
    		// signer.RoleName = ('Signer 1'); // Must match the template role
    		// //.withRoutingOrder(1);



        dfsle.Envelope dsEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(mySourceId)) // The initiating Salesforce entity--current SF user (salesperson)
            .withDocuments(new List<dfsle.Document> {
            dfsle.Document.fromTemplate(dfsle.UUID.parse(template), description)
            })
            .withRecipients(new List<dfsle.Recipient> {
            dfsle.Recipient.newEmbeddedSigner()
            .withRole('Dev') // An embedded signer
            }
        );

		
        
        
    	// Send the envelope.
        dsEnvelope = dfsle.EnvelopeService.sendEnvelope(
            dsEnvelope, // The envelope to send
            true // Send now?
        );
        // Return string value of DocuSign envelope ID
        return String.valueOf(dsEnvelope.docuSignId);
	}

    @AuraEnabled
    public static String getEmbeddedSigningUrl(String envId, String url) {
      Url mySigningUrl = dfsle.SigningService.getEmbeddedSigningUrl(
        dfsle.UUID.parse(envId), // envId value as a UUID
        new URL(url) // url value as a URL
      );
    
      // Return string value of Url to controlle
      return mySigningUrl.toExternalForm();

	}

	 @AuraEnabled
    public static List<dfsle.Document> fetchSignedDocuments(String envelopeIdStr, Id recordId) {
		System.debug('envelopeIdStr--->'+envelopeIdStr);

		dfsle__Envelope__c env = [SELECT Id, dfsle__DocuSignId__c FROM dfsle__Envelope__c where dfsle__DocuSignId__c='5cad3c74-04f5-4bc3-aa21-b2b7956ff067'];

        
        

            List<dfsle.Document> docs =  dfsle.DocumentService.getEnvelopeDocuments(env.Id);
			System.debug('vinayak-->'+docs);
            Integer count = 0;

            for (dfsle.Document doc : docs) {
                Attachment att = new Attachment();
                att.Name = doc.name;
                // att.Body = doc.sourceId;
                // att.ParentId = recordId;
                // insert att;
                count++;
            }
		return docs;

        
    }

 

}