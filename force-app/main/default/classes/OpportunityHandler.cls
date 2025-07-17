// Gère les opportunités gagnées et ajuste le stock des produits.

public with sharing class OpportunityHandler {
   //autocall quand une opp passe à "Closed Won"
    public static void processClosedWonOpportunities(List<Opportunity> opportunities) {

        // entrée méthode et nb opp traitées.
        System.debug('DEBUG: OpportunityHandler - processClosedWonOpportunities appelée. Nombre d\'opportunités: ' + opportunities.size());

        //Extraire IDs de ces opps👆 
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }

        //recupere lignes produits (OpportunityLineItem) 

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, OpportunityId, Product2Id, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];
        // nb lignes de produit trouvées
        System.debug('DEBUG: OpportunityHandler - Nombre de lignes de produit trouvées: ' + lineItems.size());


        Map<Id, Product2> produitsAmettreAJour = new Map<Id, Product2>();
         //Contrôle des stocks disponibles
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
                    p.QuantityInStock__c -= oli.Quantity;//decrementer le stock
                    produitsAmettreAJour.put(p.Id, p); //ajouter le produit à la map pour mise à jour
                }
            }
        }

        if (!produitsAmettreAJour.isEmpty()) {
            // Indique la tentative de mise à jour finale des produits.
            System.debug('DEBUG: OpportunityHandler - mise à jour des produits. Nombre: ' + produitsAmettreAJour.size());
            update produitsAmettreAJour.values();//MAJ produits
        }
    }
}