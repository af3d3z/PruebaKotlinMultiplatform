package org.alebozek.prueba

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform