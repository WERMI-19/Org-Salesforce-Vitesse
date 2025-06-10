public with sharing class OpportunityHandler {

    public static void processClosedWonOpportunities(List<Opportunity> opportunities) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, OpportunityId, Product2Id, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        Map<Id, Product2> produitsAmettreAJour = new Map<Id, Product2>();

        for (OpportunityLineItem oli : lineItems) {
            if (oli.Product2.QuantityInStock__c == null || oli.Quantity > oli.Product2.QuantityInStock__c) {
                for (Opportunity opp : opportunities) {
                    if (opp.Id == oli.OpportunityId) {
                        opp.addError(Label.Error_Stock); // Erreur internationalisée
                    }
                }
                return;
            } else {
                Product2 p = oli.Product2;
                p.QuantityInStock__c -= oli.Quantity;
                produitsAmettreAJour.put(p.Id, p);
            }
        }

        if (!produitsAmettreAJour.isEmpty()) {
            update produitsAmettreAJour.values();
        }
    }
}

