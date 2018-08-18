package hu.guideme.server

import hu.guideme.api.Project

import io.vertx.core.AbstractVerticle
import io.vertx.core.Future
import io.vertx.core.http.HttpServerResponse
import io.vertx.core.json.*
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
import io.vertx.kotlin.core.json.*
import java.time.format.DateTimeFormatter 
import java.time.LocalDate


class InternalAPIVerticle : AbstractVerticle() {

    private val logger = LoggerFactory.getLogger(InternalAPIVerticle::class.java)

    private lateinit var jdbc : AsyncSQLClient;

    //TODO a datumot lehet valahogy localolni, meg kene oldani
    // val dateFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd") 

    private val router = Router.router(vertx).apply {

        route().handler(BodyHandler.create())

        get("/cucc/get/:id").handler { ctx ->
            val id = ctx.request().getParam("id").toInt()

            jdbc.getConnection { res ->
                if (res.succeeded()) {
                    val conn = res.result()

                    var query = "SELECT * FROM Cucc WHERE id = ?"
                    var params = json { array(id) }

                    conn.queryWithParams(query, params) { res -> 
                               
                        if (res.failed()){
                            logger.error("get:/cucc/get/:id Update failed : ${res.cause()}")
                            ctx.fail(500)
                        }else{
                            //TODO city meg user fieldet lehet ki kene bontani
                            ctx.response().endWithJson(res.result().getRows()[0])
                        }
                    }

                } else {
                    logger.error("get:/cucc/get/:id getConnection failed : ${res.cause()}")
                    ctx.fail(500)
                }
            }
        }

        get("/cucc/list").handler { ctx ->
            //TODO elesben enm kene ilyen listazasokat hasznalnuk ha kurvanagy lesz

            jdbc.getConnection { res ->
                if (res.succeeded()) {
                    val conn = res.result()

                    var query = "SELECT * FROM Cucc"

                    conn.query(query) { res -> 
                               
                        if (res.failed()){
                            logger.error("get:/cucc/list Update failed : ${res.cause()}")
                            ctx.fail(500)
                        }else{
                            //TODO city meg user fieldet lehet ki kene bontani
                            ctx.response().endWithJson(res.result().getRows())
                        }
                    }

                } else {
                    logger.error("get:/cucc/list getConnection failed : ${res.cause()}")
                    ctx.fail(500)
                }
            }
        }

        // add a new Cucc
        post("/cucc").handler { ctx ->
            val cucc = ctx.getBodyAsJson()

            jdbc.getConnection { res ->
                if (res.succeeded()) {
                    val conn = res.result()

                    // Got a connection
                    val update = "INSERT INTO Cucc(user, city, begin, end) VALUE (?, ?, ?, ?)"

                    var params = json { array(
                            cucc.getInteger("user"),
                            cucc.getInteger("city"),
                            cucc.getString("begin"),
                            cucc.getString("end")
                    )}

                    conn.updateWithParams(update, params) { res -> 
                               
                        if (res.failed()){
                            logger.error("post:/cucc Update failed : ${res.cause()}")
                            ctx.fail(500)
                        }else{
                            ctx.response().endWithJson(res.result().toJson())
                        }
                    }

                } else {
                    logger.error("post:/cucc getConnection failed : ${res.cause()}")
                    ctx.fail(500)
                }
            }
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