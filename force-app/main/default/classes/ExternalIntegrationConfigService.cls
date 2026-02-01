public with sharing class ExternalIntegrationConfigService {

    public class IntegrationConfig {
        public String namedCredential;
        public Integer timeoutMs;
        public Boolean isActive;
    }

    public static IntegrationConfig getConfig(String integrationDeveloperName) {

        ExternalIntegrationSettings__mdt setting = ExternalIntegrationSettings__mdt.getInstance(integrationDeveloperName);

        if (setting == null) {
            throw new CalloutException(
                'Integration config not found for: ' + integrationDeveloperName
            );
        }

        IntegrationConfig config = new IntegrationConfig();
        config.namedCredential = setting.NamedCredential__c;
        config.isActive = setting.IsActive__c;
        config.timeoutMs = setting.Timeout__c != null ? Integer.valueOf(setting.Timeout__c) : 20000;
        return config;
    }
}
