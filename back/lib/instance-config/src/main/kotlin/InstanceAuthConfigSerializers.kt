package instanceconfig

import kotlinx.serialization.modules.SerializersModule

/**
 * Carrier for the polymorphic [SerializersModule] contributed by an
 * [InstanceAuthConfig] adapter. The active deploy provides a single instance
 * via Koin (registering its own [InstanceAuthConfig] subtype); the routing
 * layer composes it into the Json used for ContentNegotiation so that the
 * discovery endpoint can serialize the deploy's variant.
 */
class InstanceAuthConfigSerializers(
    val module: SerializersModule,
)
