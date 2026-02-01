public with sharing class ProductSyncFlowController {
    public class FlowInput {
        @InvocableVariable(label='Run Sync')
        public Boolean runSync;
    }
    
    public class FlowOutput {

        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Products Count')
        public Integer productsCount;
    }

    @InvocableMethod(
        label='Sync Products and Prices' description='Triggers the external integration and synchronizes Product2 and PricebookEntry')
    public static List<FlowOutput> syncProducts(List<FlowInput> inputs) {

        List<FlowOutput> results = new List<FlowOutput>();

        for (FlowInput input : inputs) {

            FlowOutput output = new FlowOutput();

            try {
                ProductAndPriceSyncService.syncProducts();
                Integer countProducts = [
                    SELECT COUNT()
                    FROM Product2
                    WHERE cgcloud__Consumer_Goods_External_Product_Id__c != null AND CREATEDDATE = TODAY
                ];

                output.success = true;
                output.productsCount = countProducts;
                output.message = 'Synchronization completed successfully. Total products synchronized: ' + countProducts + '.';

            } catch (Exception e) {

                output.success = false;
                output.productsCount = 0;
                output.message = 'Synchronization failed. Error: ' + e.getMessage();
            }

            results.add(output);
        }
        return results;
    }
}
