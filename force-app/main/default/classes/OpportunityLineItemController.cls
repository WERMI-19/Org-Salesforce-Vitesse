public with sharing class OpportunityLineItemController {

    /**
     * Récupère les lignes de produit associées à une opportunité.
     * Utilisé pour afficher les produits liés à une opportunité dans un composant LWC ou Aura.
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
     * Supprime une ligne de produit de l'opportunité.
     * On laisse Salesforce gérer automatiquement les erreurs (ex : ID inexistant).
     */
    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        delete new OpportunityLineItem(Id = lineItemId);
    }

    /**
     * Met à jour le stock de plusieurs produits à partir d’une liste de maps clé/valeur.
     * Ignore les entrées invalides sans bloquer l’exécution.
     */
    @AuraEnabled
    public static void updateProductStock(List<Map<String, Object>> updates) {
        List<Product2> produitsAMettreAJour = new List<Product2>();

        // Rien à faire si la liste est vide ou nulle
        if (updates == null || updates.isEmpty()) {
            return;
        }

        for (Map<String, Object> ligne : updates) {
            try {
                // On vérifie que les clés nécessaires sont présentes
                if (ligne == null || !ligne.containsKey('productId') || !ligne.containsKey('quantityInStock')) {
                    continue;
                }

                // Conversion de la quantité vers Decimal (via String pour plus de robustesse)
                Id productId = (Id) ligne.get('productId');
                Decimal quantity = Decimal.valueOf(String.valueOf(ligne.get('quantityInStock')));

                produitsAMettreAJour.add(new Product2(Id = productId, QuantityInStock__c = quantity));
            } catch (Exception e) {
                // On ignore discrètement les lignes incorrectes sans planter toute l'opération
                continue;
            }
        }

        // Mise à jour en masse si on a des produits valides à modifier
        if (!produitsAMettreAJour.isEmpty()) {
            update produitsAMettreAJour;
        }
    }
}
