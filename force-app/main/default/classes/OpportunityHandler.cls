// Classe pour les opportunités gagnées
public class OpportunityHandler {

    // Vérifie la quantité de stock disponible
    public static void processClosedWonOpportunities(List<Opportunity> opportunities) {

        // Récupérer les IDs des opportunités
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }

        // Requête des lignes liées à l’opportunité
        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, Product2Id, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        // Parcourir les lignes de produit
        for (OpportunityLineItem oli : lineItems) {

            // Vérifier si quantité dépasse le stock
            if (oli.Quantity > oli.Product2.QuantityInStock__c) {

                // Ajouter une erreur à l’opportunité
                for (Opportunity opp : opportunities) {
                    opp.addError('Votre opportunité ne peut pas être mise à jour car vous avez un souci de quantité sur vos lignes.');
                }

                return; // Arrêter le traitement immédiatement
            }
        }
    }
}
