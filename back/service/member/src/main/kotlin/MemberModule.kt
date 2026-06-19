package member

import core.CoreModule
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

@Module(includes = [CoreModule::class])
@ComponentScan
class MemberModule
