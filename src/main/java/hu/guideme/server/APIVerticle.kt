package hu.guideme.server

import io.vertx.core.AbstractVerticle
import io.vertx.core.Future
import io.vertx.core.http.HttpServerResponse
import io.vertx.core.json.Json
import io.vertx.core.json.JsonObject
import io.vertx.core.net.PemKeyCertOptions
import io.vertx.ext.asyncsql.AsyncSQLClient
import io.vertx.ext.asyncsql.MySQLClient
import io.vertx.ext.sql.ResultSet
import io.vertx.ext.sql.SQLConnection
import io.vertx.ext.sql.UpdateResult
import io.vertx.ext.web.Router
import io.vertx.ext.web.RoutingContext
import io.vertx.kotlin.core.http.HttpServerOptions
import io.vertx.kotlin.core.json.array
import io.vertx.kotlin.core.json.json
import io.vertx.kotlin.core.json.obj
import org.slf4j.LoggerFactory


abstract class APIVerticle : AbstractVerticle() {

    protected val logger = LoggerFactory.getLogger(javaClass)

    protected lateinit var jdbc : AsyncSQLClient

    protected val router = Router.router(vertx)

    // MYSQL HELPER FUNCTIONS

    protected fun query(ctx: RoutingContext, query: String, vararg params: Any, handler: (RoutingContext, ResultSet) -> Unit) {
        jdbc.getConnection { res ->
            if (res.succeeded()) {
                val conn = res.result()

                conn.queryWithParams(query, json { array(*params) }) { res -> 
                            
                    if (res.failed()){
                        ctx.fail(res.cause())
                        // logger.error("$query query with params: $params failed: ${res.cause()}")
                        // ctx.fail(500)
                    }else{
                        //TODO pl user fieldet lehet ki kene bontani
                        handler(ctx, res.result())
                        // ctx.response().endWithJson(res.result().getRows()[0])
                    }

                    conn.close()
                }

            } else {
                logger.error("getConnection failed : ${res.cause()}")
                ctx.fail(500)
            }
        }
    }

    protected fun update(ctx: RoutingContext, update: String, vararg params: Any?, handler: (RoutingContext, UpdateResult) -> Unit){
        jdbc.getConnection { res ->
            if (res.succeeded()) {
                // Got a connection
                val conn = res.result()

                conn.updateWithParams(update, json { array(*params)}) { res -> 
                            
                    if (res.failed()){
                        val error = res.cause()?.message?.split(" - ")
                        
                        logger.info("***** ${error}")

                        if(error != null && error[1] == "45000"){
                            ctx.fail(400)
                        }else{
                            //TODO arror handling
                            logger.error("$update Update with params: $params failed : ${res.cause()}")
                            ctx.fail(500)
                        }

                    }else{
                        handler(ctx, res.result())
                    }

                    conn.close()
                }

            } else {
                logger.error("getConnection failed : ${res.cause()}")
                ctx.fail(500)
            }
        }
    }

    /**
    * Helper function for updateTransaction
    * ~recursive
    * executes an update from the list
    * rollbacks on fail
    */
    private fun updateTransactionUpdater(conn: SQLConnection, updates: List<Pair<String, Array<Any>>>, ctx: RoutingContext, handler: (RoutingContext) -> Unit ){
        if(updates.isNotEmpty()){
            val update = updates[0]

            conn.updateWithParams(update.first, json{ array(*update.second) }) { res ->
                if(res.failed()){
                    // one update failed -> roll back and send fail
                    conn.rollback() { _ ->
                        logger.error("$updates UpdateTransaction failed : ${res.cause()}")
                    }
                    ctx.fail(res.cause())
                }else{
                    // success -> exceute the next update
                    updateTransactionUpdater(conn, updates.drop(1), ctx, handler)
                }

            }

        }else{
            // consumed all the updates successfully
            conn.commit() { res -> 
                if (res.failed()) {
                    logger.error("$updates UpdateTransaction during commit() failed : ${res.cause()}")
                    ctx.fail(500)
                }
                
                conn.close()

                handler(ctx)
            }
        }
    }

    /**
    * excecute updates with autoCommit(false)
    * the updates are only commited if none of the updates have failed
    */
    protected fun updateTransaction(ctx: RoutingContext, vararg updates: Pair<String, Array<Any>>, handler: (RoutingContext) -> Unit) {
        jdbc.getConnection{ res ->
            if (res.succeeded()) {
                // Got a connection

                val conn = res.result()
                
                conn.setAutoCommit(false) { res -> 
                    if (res.failed()) {
                        ctx.fail(res.cause())
                    }

                    val updateList = listOf<Pair<String, Array<Any>>>(*updates)

                    updateTransactionUpdater(conn, updateList, ctx, handler)
                }

            }else{
                logger.error("getConnection failed : ${res.cause()}")
                ctx.fail(500)
            }
        }
    }

    // VERTICLE FUNCTIONS
    
    override fun start(fut: Future<Void>?){
        initDatabase(fut!!)
    }

    private fun initDatabase(fut: Future<Void>){
        jdbc = MySQLClient.createNonShared(vertx, config().getJsonObject("database"))

        jdbc.getConnection {
            if (it.failed()) {
                fut.fail(it.cause())
            } else {
                logger.info("database connected")
                initHttp(fut)
            }
        }
    }

    private fun initHttp(fut: Future<Void>){

        val options = HttpServerOptions()

        // ssl setup
        if(config().containsKey("pem")){
            val pemConfig = config().getJsonObject("pem")
            val key = vertx.fileSystem().readFileBlocking(pemConfig.getString("key"))
            val cert = vertx.fileSystem().readFileBlocking(pemConfig.getString("cert"))

            println(key)
            println(cert)

            val pemOptions = PemKeyCertOptions()
            pemOptions.keyValue = key
            pemOptions.certValue = cert

            options.isSsl = true
            options.pemKeyCertOptions = pemOptions
        }

        vertx.createHttpServer(options)
            .requestHandler({ router.accept(it) })
            .listen(config().getInteger("port")) {
                if (it.failed()) {
                    fut.fail(it.cause())
                }else{
                    fut.complete()
                }
            }
    }

    // HELPER FUNCTIONS

    fun HttpServerResponse.endWithJson(obj: Any) {
        this.putHeader("Content-Type", "application/json; charset=utf-8")
            .end(Json.encodePrettily(obj))
    }

    fun io.vertx.core.json.JsonObject.unflatten(): JsonObject {
        
        fieldNames().toList().forEach {
            if(it.contains('.')){
                val path = it.split('.')
                val name = path.drop(1).joinToString(".")
                val parent = path[0]
                val value = getValue(it)
                
                remove(it)
                
                if(containsKey(parent)){
                    getJsonObject(parent).put(name, value)
                }else{
                    put(parent, json { obj( name to value ) })
                }
            }
        }

        fieldNames().toList().forEach {
            val obj = getValue(it)
            if(obj is JsonObject)
                obj.unflatten()
        }

        return this
    }
}