public with sharing class ProductAndPriceSyncService {

    public static void syncProducts() {

        // 1. Buscar produtos da API
        List<ExternalProductPayload.Product> externalProducts =
            FakeStoreProductService.fetchProducts();

        if (externalProducts.isEmpty()) {
            return;
        }

        // 2. Mapear produtos externos → Product2
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

        // 3. Upsert Product2
        System.debug('Upsert Product2: ' + productsToUpsert);
        upsert productsToUpsert cgcloud__Consumer_Goods_External_Product_Id__c;

        // 4. Buscar Standard Price Book
        Id standardPricebookId = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ].Id;

        // 5. Buscar PricebookEntries existentes
        Map<Id, PricebookEntry> existingPBEsByProduct =
            new Map<Id, PricebookEntry>();

        for (PricebookEntry pbe : [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND Product2Id IN :productsToUpsert
        ]) {
            existingPBEsByProduct.put(pbe.Product2Id, pbe);
        }

        // 6. Criar / atualizar PricebookEntries
        List<PricebookEntry> pbesToInsert = new List<PricebookEntry>();
        List<PricebookEntry> pbesToUpdate = new List<PricebookEntry>();

        for (Product2 p : productsToUpsert) {

            Decimal price = externalIdToPrice.get(
                p.cgcloud__Consumer_Goods_External_Product_Id__c
            );

            if (existingPBEsByProduct.containsKey(p.Id)) {

                // UPDATE
                PricebookEntry existing = existingPBEsByProduct.get(p.Id);
                existing.UnitPrice = price;
                existing.IsActive = true;
                pbesToUpdate.add(existing);

            } else {

                // INSERT
                PricebookEntry pbe = new PricebookEntry();
                pbe.Product2Id = p.Id;
                pbe.Pricebook2Id = standardPricebookId;
                pbe.UnitPrice = price;
                pbe.IsActive = true;
                pbe.UseStandardPrice = false;
                pbesToInsert.add(pbe);
            }
        }

        // 7. Executar DML
        if (!pbesToInsert.isEmpty()) {
            insert pbesToInsert;
        }

        if (!pbesToUpdate.isEmpty()) {
            update pbesToUpdate;
        }
    }
}
