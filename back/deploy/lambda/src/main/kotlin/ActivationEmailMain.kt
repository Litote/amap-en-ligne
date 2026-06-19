package deploy.lambda

import com.asyncant.aws.lambda.runtime.runLambda

fun activationEmailMain() {
    val lambda = ActivationEmailLambda()
    runLambda { event, _ -> lambda.handleRequest(event) }
}
