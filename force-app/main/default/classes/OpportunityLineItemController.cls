// Contrôleur pour les lignes d’opportunité
public with sharing class OpportunityLineItemController {

    // Récupère les lignes de l’opportunité
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   Product2.Id, Product2.Name, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
    }

    // Supprime une ligne d’opportunité
    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        if (lineItemId == null) {
            // Lancer erreur si Id est nul
            throw new AuraHandledException('Id de la ligne est null, suppression impossible !');
        }
        try {
            // Supprimer la ligne par Id
            delete new OpportunityLineItem(Id = lineItemId);
        } catch (Exception e) {
            // Remonter l’erreur capturée
            throw new AuraHandledException('Erreur suppression: ' + e.getMessage());
        }
    }

    // Met à jour les stocks produits
    @AuraEnabled
    public static void updateProductStock(List<Map<String, Object>> updates) {
        List<Product2> productsToUpdate = new List<Product2>();

        for (Map<String, Object> row : updates) {
            try {
                // Extraire les valeurs du map
                Id productId = (Id)row.get('productId');
                Integer qty = Integer.valueOf(row.get('quantityInStock') + '');

                // Ajouter le produit à mettre à jour
                if (productId != null && qty != null) {
                    productsToUpdate.add(new Product2(Id = productId, QuantityInStock__c = qty));
                } else {
                    // Données manquantes ignorées
                    System.debug('Ligne ignorée: données manquantes ' + row);
                }
            } catch (Exception e) {
                // Erreur de conversion capturée
                System.debug('Erreur parsing ligne: ' + e.getMessage());
            }
        }

        // Mettre à jour les produits si nécessaires
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
    }
}

