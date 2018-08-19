package hu.guideme.server

import io.vertx.core.DeploymentOptions
import io.vertx.core.Vertx
import io.vertx.core.json.JsonObject
import org.slf4j.LoggerFactory
import java.io.File


object Main{
    
    private val logger = LoggerFactory.getLogger(Main::class.java)

    val conf = JsonObject(File("config.json").readText())

    @JvmStatic
    fun main(args: Array<String>) {
        val vertx = Vertx.vertx()

        val internalAPIOptions = DeploymentOptions().setConfig(conf.getJsonObject("internalAPI"))
        vertx.deployVerticle("hu.guideme.server.InternalAPIVerticle", internalAPIOptions) {
            if(it.failed()){
                logger.error("starting InternalAPIVerticle failed\n" + it.cause())
                it.cause().printStackTrace()
                kotlin.system.exitProcess(1)
            }else{
                logger.info("InternalAPIVerticle started successfully")
            }
        }

        val adminApiOptions = DeploymentOptions().setConfig(conf.getJsonObject("adminAPI"))
        vertx.deployVerticle("hu.guideme.server.AdminAPIVerticle", adminApiOptions) {
            if(it.failed()){
                logger.error("starting AdminAPIVerticle failed\n" + it.cause())
                kotlin.system.exitProcess(1)
            }else{
                logger.info("AdminAPIVerticle started successfully")
            }
        }
    }
}