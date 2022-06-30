param location string = resourceGroup().location

resource managedClusters 'Microsoft.ContainerService/managedClusters@2021-08-01' = [for i in range(0, 3): {
  name: 'bicep-cluster${i}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'my-cluster-9c984f${i}'
    agentPoolProfiles: [
      {
        name: 'agentpool1'
        count: 2
        vmSize: 'Standard_D2_v2'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
      }
    ]
  }
}]

resource fluxExtensions 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = [for i in range(0, 3): {
  name: 'flux'
  properties: {
    extensionType: 'microsoft.flux'
  }
  scope: managedClusters[i]
}]

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01' = [for i in range(0, 3): {
  name: 'bicep-fluxconfig'
  properties: {
    scope: 'cluster'
    namespace: 'cluster-config'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: 'https://github.com/Azure/gitops-flux2-kustomize-helm-mt'
      repositoryRef: {
        branch: 'main'
      }
      syncIntervalInSeconds: 120
    }
    kustomizations: {
      'infra': {
        path: './infrastructure'
        syncIntervalInSeconds: 120
      }
      'apps': {
        path: './apps/production'
        syncIntervalInSeconds: 120
        dependsOn: [
          'infra'
        ]
      }
    }
    configurationProtectedSettings: {
      'sshPrivateKey': '<base64-encoded-pem-private-key>'
    }
  }
  dependsOn: [
    fluxExtensions[i]
  ]
  scope: managedClusters[i]
}]
