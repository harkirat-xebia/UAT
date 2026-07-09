public without sharing class EmbeddedSigningController {

    @AuraEnabled
    public static String sendEnvelope(String template, String description, Id recordId) {
        // Block DocuSign send for Framework Agreement quotes where scope has not been defined
        String recordPrefix = String.valueOf(recordId).left(3);
        if (recordPrefix == '0Q0') {
            Quote q = [SELECT Is_Framework_Agreement__c, Framework_Scope_Defined__c
                       FROM Quote WHERE Id = :recordId LIMIT 1];
            if (q.Is_Framework_Agreement__c && !q.Framework_Scope_Defined__c) {
                throw new AuraHandledException(
                    'FRAMEWORK_SCOPE_UNDEFINED:Please define the framework scope before sending for signature.'
                );
            }
        }

        try {
            dfsle.Envelope dsEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(recordId))
                .withDocuments(new List<dfsle.Document>{
                    dfsle.Document.fromTemplate(dfsle.UUID.parse(template), description)
                })
                .withRecipients(new List<dfsle.Recipient>{
                    dfsle.Recipient.newEmbeddedSigner().withRole('Dev')
                });

            dsEnvelope = dfsle.EnvelopeService.sendEnvelope(dsEnvelope, true);
            return String.valueOf(dsEnvelope.docuSignId);

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send envelope: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getEmbeddedSigningUrl(String envId, String url) {
        try {
            Url signingUrl = dfsle.SigningService.getEmbeddedSigningUrl(
                dfsle.UUID.parse(envId),
                new URL(url)
            );
            return signingUrl.toExternalForm();
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve signing URL: ' + e.getMessage());
        }
    }
}
