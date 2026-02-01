public with sharing class FakeStoreProductService {

    public static List<ExternalProductPayload.Product> fetchProducts() {

        ExternalIntegrationConfigService.IntegrationConfig config =
            ExternalIntegrationConfigService.getConfig('FakeStoreAPI');

        if (!config.isActive) {
            throw new CalloutException('Integration inactive');
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('callout:' + config.namedCredential + '/products');
        req.setTimeout(config.timeoutMs);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(res.getBody());
        }

        ExternalProductPayload response = (ExternalProductPayload) JSON.deserialize(res.getBody(),
                ExternalProductPayload.class);

        if (response == null || response.products == null) {
            throw new CalloutException('Products not found in response');
        }
        return response.products;
    }
}
