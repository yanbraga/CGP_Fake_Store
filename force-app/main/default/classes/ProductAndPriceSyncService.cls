public with sharing class ProductAndPriceSyncService {

    public static void syncProducts() {

        List<ExternalProductPayload.Product> externalProducts = FakeStoreProductService.fetchProducts();

        if (externalProducts.isEmpty()) {
            return;
        }

        List<Product2> productsToUpsert = new List<Product2>();
        Map<String, Decimal> externalIdToPrice = new Map<String, Decimal>();

        for (ExternalProductPayload.Product product : externalProducts) {

            String externalId = String.valueOf(product.id);

            Product2 p = new Product2();
            p.Name = product.title;
            p.IsActive = true;
            p.DisplayUrl = product.image;
            p.cgcloud__Category__c = product.category;
            p.cgcloud__Consumer_Goods_External_Product_Id__c = externalId;

            productsToUpsert.add(p);
            externalIdToPrice.put(externalId, product.price);
        }

        upsert productsToUpsert cgcloud__Consumer_Goods_External_Product_Id__c;

        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        Map<Id, PricebookEntry> existingPBEsByProduct = new Map<Id, PricebookEntry>();

        for (PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId AND Product2Id IN :productsToUpsert]){
            existingPBEsByProduct.put(pbe.Product2Id, pbe);
        }

        List<PricebookEntry> pbesToInsert = new List<PricebookEntry>();
        List<PricebookEntry> pbesToUpdate = new List<PricebookEntry>();

        for (Product2 p : productsToUpsert) {

            Decimal price = externalIdToPrice.get(p.cgcloud__Consumer_Goods_External_Product_Id__c);

            if (existingPBEsByProduct.containsKey(p.Id)) {
                PricebookEntry existing = existingPBEsByProduct.get(p.Id);
                existing.UnitPrice = price;
                existing.IsActive = true;
                pbesToUpdate.add(existing);

            } else {
                PricebookEntry pbe = new PricebookEntry();
                pbe.Product2Id = p.Id;
                pbe.Pricebook2Id = standardPricebookId;
                pbe.UnitPrice = price;
                pbe.IsActive = true;
                pbe.UseStandardPrice = false;
                pbesToInsert.add(pbe);
            }
        }

        if (!pbesToInsert.isEmpty()) {
            insert pbesToInsert;
        }

        if (!pbesToUpdate.isEmpty()) {
            update pbesToUpdate;
        }
    }
}
