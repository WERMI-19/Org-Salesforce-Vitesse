public with sharing class OpportunityLineItemController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   Product2.Id, Product2.Name, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
    }

    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        delete new OpportunityLineItem(Id = lineItemId);
    }

    @AuraEnabled
    public static void updateProductStock(List<Map<String, Object>> updates) {
        List<Product2> productsToUpdate = new List<Product2>();

        for (Map<String, Object> row : updates) {
            try {
                Id productId = (Id)row.get('productId');
                Integer qty = Integer.valueOf(row.get('quantityInStock') + '');

                if (productId != null && qty != null) {
                    productsToUpdate.add(new Product2(Id = productId, QuantityInStock__c = qty));
                }
            } catch (Exception e) {
                // Ignorer les données invalides
            }
        }

        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
    }
}
