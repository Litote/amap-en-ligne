package deploy.lambda

import authentication.CognitoAuthenticationModule
import email.delivery.EmailDeliveryModule
import http.HttpModule
import instanceconfig.CognitoInstanceConfigModule
import lambda.ktor.APIGatewayLambdaBase
import lambda.startKoin
import org.koin.core.KoinApplication
import org.koin.ksp.generated.module
import persistence.dynamo.DynamoModule
import provisioning.cognito.ProvisioningCognitoModule
import routing.dataRoutingModule
import sync.SyncModule

class DataLambda(
    koin: KoinApplication =
        startKoin(
            SyncModule().module,
            DynamoModule().module,
            CognitoAuthenticationModule().module,
            CognitoInstanceConfigModule().module,
            HttpModule().module,
            LambdaEmailModule().module,
            EmailDeliveryModule().module,
            ProvisioningCognitoModule().module,
        ),
) : APIGatewayLambdaBase(koin, { koinApp -> dataRoutingModule(koinApp) })
