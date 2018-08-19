package hu.guideme.server

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

class AdminAPIVerticle : APIVerticle() {

    private val USER_FIELDS = "User.id AS `user.id`, User.username AS `user.username`, User.realname AS `user.realname`, User.email AS `user.email`, User.avatar AS `user.avatar`"
    private val CATEGORY_FIELDS = "Category.id AS `category.id`, Category.name AS `category.name`"

    init {
        router.apply {

            route().handler(BodyHandler.create())

            get("/shutdown").handler { ctx ->
               System.exit(1)
            }

            post("/backup_database").handler { ctx ->
                // val body = ctx.getBodyAsJson();
                // val fileName = body.getString("file_name");
                println(ctx.bodyAsString)
                ctx.response().end("okimoki teso")
            }

            get("/re_init_database").handler { ctx ->


                val id = ctx.request().getParam("id").toInt()

                // ctx.response().endWithJson(Main.database.getProject(id))
            }

            // REWARD

            get("/rewards").handler { ctx ->
                query(ctx, """SELECT
                            Reward.id, Reward.name, Reward.goal, Reward.description,
                            $CATEGORY_FIELDS
                            FROM Reward, Category
                            WHERE Reward.category = Category.id
                            """) { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map { it.unflatten() })
                }
            }

            get("/rewards/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()

                query(ctx, """SELECT * FROM Reward WHERE id = ?""", id){ ctx, res ->
                    ctx.response().endWithJson(res.rows[0].unflatten() )
                }
            }

            post("/rewards").handler { ctx->
                val reward = ctx.bodyAsJson

                update(ctx, """INSERT INTO Reward(name, description, category, goal) VALUES (?, ?, ?, ?)""",
                        reward.getString("name"),
                        reward.getString("description"),
                        reward.getInteger("category"),
                        reward.getInteger("goal")){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            put("/rewards/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                val reward = ctx.bodyAsJson

                update(ctx, """UPDATE Reward SET name = ?, description = ?, category = ?, goal = ? WHERE id = ?""",
                        reward.getString("name"),
                        reward.getString("description"),
                        reward.getInteger("category"),
                        reward.getInteger("goal"),
                        id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            delete("/rewards/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()

                update(ctx, """DELETE FROM Reward WHERE id = ?""", id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            // CATEGORY

            get("/categories").handler { ctx ->
                query(ctx, """SELECT * FROM Category""") { ctx, res ->
                    ctx.response().endWithJson(res.rows.map { it.unflatten() })
                }
            }

            get("/categories/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                query(ctx, """SELECT * FROM Category WHERE id = ?""", id) { ctx, res ->
                    ctx.response().endWithJson(res.rows[0].unflatten())
                }
            }

            put("/categories/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                val category = ctx.bodyAsJson

                println(id)
                println(category.getString("name"))

                update(ctx, """UPDATE Category SET name = ? WHERE id = ?""",
                        category.getString("name"),
                        id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }


            post("/categories").handler { ctx->
                val category = ctx.bodyAsJson

                update(ctx, """INSERT INTO Category(name) VALUES (?)""",
                        category.getString("name")){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            delete("/categories/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()

                update(ctx, """DELETE FROM Category WHERE id = ?""", id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

        }
    }
}