package deploy.lambda

import instanceconfig.CognitoInstanceConfigModule
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import persistence.dynamo.DynamoModule
import properties.PropertiesModule

@Module(includes = [PropertiesModule::class, CognitoInstanceConfigModule::class, DynamoModule::class])
@ComponentScan("deploy.lambda")
class LambdaEmailModule
