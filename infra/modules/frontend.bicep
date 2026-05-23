param location string
param suffix string
param tags object
param envId string
param acrServer string
param acrName string
@secure()
param acrPassword string
param aiConnStr string
param apiUrl string
param dtOtlpEndpoint string = ''
param dtOtlpToken string = ''

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'frontend-${suffix}'
  location: location
  tags: union(tags, { 'azd-service-name': 'frontend' })
  identity: { type: 'SystemAssigned' }
  properties: {
    managedEnvironmentId: envId
    configuration: {
      secrets: concat([
        { name: 'acr-password', value: acrPassword }
      ], !empty(dtOtlpToken) ? [
        { name: 'dt-otlp-token', value: dtOtlpToken }
      ] : [])
      registries: [
        { server: acrServer, username: acrName, passwordSecretRef: 'acr-password' }
      ]
      ingress: { external: true, targetPort: 3000 }
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: concat([
            { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: aiConnStr }
            { name: 'GATEWAY_URL', value: apiUrl }
          ], !empty(dtOtlpEndpoint) ? [
            { name: 'DT_OTLP_ENDPOINT', value: dtOtlpEndpoint }
            { name: 'DT_OTLP_TOKEN', secretRef: 'dt-otlp-token' }
          ] : [])
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 3 }
    }
  }
}

output url string = 'https://${app.properties.configuration.ingress.fqdn}'
