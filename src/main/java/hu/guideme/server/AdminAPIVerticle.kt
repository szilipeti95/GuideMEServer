package hu.guideme.server

import hu.guideme.api.Project

import io.vertx.core.AbstractVerticle
import io.vertx.core.Future
import io.vertx.core.http.HttpServerResponse
import io.vertx.core.json.Json
import io.vertx.core.json.JsonObject
import io.vertx.ext.web.Router
import io.vertx.ext.web.RoutingContext
import io.vertx.ext.web.handler.BodyHandler
import io.vertx.ext.web.handler.StaticHandler
import io.vertx.kotlin.core.http.HttpServerOptions
import io.vertx.core.json.*
import io.vertx.ext.jdbc.*
import io.vertx.ext.sql.*
import io.vertx.ext.asyncsql.MySQLClient
import io.vertx.ext.asyncsql.*
import io.vertx.core.DeploymentOptions 
import org.slf4j.LoggerFactory

class AdminAPIVerticle : AbstractVerticle() {

    private val logger = LoggerFactory.getLogger(AdminAPIVerticle::class.java)

    private lateinit var jdbc : AsyncSQLClient;

    private val router = Router.router(vertx).apply {

        route().handler(BodyHandler.create())

        post("/backup_database").handler { ctx ->
            // val body = ctx.getBodyAsJson();
            // val fileName = body.getString("file_name");
            println(ctx.getBodyAsString())
            ctx.response().end("okimoki teso")
        }

        get("/re_init_database").handler { ctx ->


            val id = ctx.request().getParam("id").toInt()

            // ctx.response().endWithJson(Main.database.getProject(id))
        }

    }

    override fun start(fut: Future<Void>?){
        initDatabase(fut!!)
    }

    private fun initDatabase(fut: Future<Void>){
        jdbc = MySQLClient.createNonShared(vertx, config().getJsonObject("database"))

        jdbc.getConnection() {
            if (it.failed()) {
                fut.fail(it.cause());
            } else {
                logger.info("database connected")
                initHttp(fut)
            }
        }
    }

    private fun initHttp(fut: Future<Void>){
        vertx.createHttpServer()
            .requestHandler({ router.accept(it) })
            .listen(config().getInteger("port")) {
                if (it.failed()) {
                    fut.fail(it.cause())
                }else{
                    fut.complete()
                }
            }
    }

    fun HttpServerResponse.endWithJson(obj: Any) {
        this.putHeader("Content-Type", "application/json; charset=utf-8")
            .end(Json.encodePrettily(obj))
    }

}