/// Identifies which auth backend implementation a server uses. The two
/// values mirror the back's `AuthenticationModule` selection
/// (CognitoAuthenticationModule vs GoTrueAuthenticationModule).
enum AuthProvider { cognito, gotrue }
