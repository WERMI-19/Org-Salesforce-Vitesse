public with sharing class OpportunityLineItemController {

    /**
     * Récupère les lignes d’opportunité associées à une opportunité donnée.
     */
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   Product2.Id, Product2.Name, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
    }

    /**
     * Supprime une ligne de produit. Lève une erreur si l’ID est null ou la suppression échoue.
     */
    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        if (lineItemId == null) {
            throw new AuraHandledException(
                'Id de la ligne est null, suppression impossible, actualiser la page ou ajouter des données valides.'
            );
        }

        try {
            delete new OpportunityLineItem(Id = lineItemId);
        } catch (Exception e) {
            throw new AuraHandledException('Erreur suppression: ' + e.getMessage());
        }
    }

    /**
     * Met à jour les stocks de plusieurs produits.
     * Ignore les lignes invalides ou incomplètes.
     */
    @AuraEnabled
    public static void updateProductStock(List<Map<String, Object>> updates) {
        List<Product2> produitsAMettreAJour = new List<Product2>();

        for (Map<String, Object> ligne : updates) {
            try {
                if (ligne == null || !ligne.containsKey('productId') || !ligne.containsKey('quantityInStock')) {
                    continue;
                }

                Id productId = (Id) ligne.get('productId');
                Decimal quantity = Decimal.valueOf(String.valueOf(ligne.get('quantityInStock')));

                produitsAMettreAJour.add(new Product2(Id = productId, QuantityInStock__c = quantity));
            } catch (Exception e) {
                // Ignore les erreurs sur les lignes mal formatées
                continue;
            }
        }

        if (!produitsAMettreAJour.isEmpty()) {
            update produitsAMettreAJour;
        }
    }
}
