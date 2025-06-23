public with sharing class OpportunityHandler {

    public static void processClosedWonOpportunities(List<Opportunity> opportunities) {
        // Ligne 1 : Indique l'entrée dans la méthode et le nombre d'opportunités traitées.
        System.debug('DEBUG: OpportunityHandler - Méthode processClosedWonOpportunities appelée. Nombre d\'opportunités: ' + opportunities.size());

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, OpportunityId, Product2Id, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];
        // Ligne 2 : Confirme le nombre de lignes de produit trouvées, essentiel pour le traitement suivant.
        System.debug('DEBUG: OpportunityHandler - Nombre de lignes de produit trouvées: ' + lineItems.size());


        Map<Id, Product2> produitsAmettreAJour = new Map<Id, Product2>();

        for (OpportunityLineItem oli : lineItems) {
            if (oli.Product2 == null || oli.Product2.QuantityInStock__c == null || oli.Quantity > oli.Product2.QuantityInStock__c) {
                for (Opportunity opp : opportunities) {
                    if (opp.Id == oli.OpportunityId) {
                        opp.addError('Votre opportunité ne peut pas être mise à jour car vous avez un souci de quantité sur vos lignes.');
                    }
                }
                return;
            } else {
                Product2 p = oli.Product2;
                if (produitsAmettreAJour.containsKey(p.Id)) {
                    produitsAmettreAJour.get(p.Id).QuantityInStock__c -= oli.Quantity;
                } else {
                    p.QuantityInStock__c -= oli.Quantity;
                    produitsAmettreAJour.put(p.Id, p);
                }
            }
        }

        if (!produitsAmettreAJour.isEmpty()) {
            // Ligne 3 : Indique la tentative de mise à jour finale des produits.
            System.debug('DEBUG: OpportunityHandler - Tentative de mise à jour des produits. Nombre: ' + produitsAmettreAJour.size());
            update produitsAmettreAJour.values();
        }
    }
}