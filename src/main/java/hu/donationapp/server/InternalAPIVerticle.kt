package hu.donationapp.server

import io.vertx.ext.web.handler.BodyHandler
import java.util.*
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.jackson2.JacksonFactory
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import io.vertx.core.Future
import io.vertx.core.buffer.Buffer
import io.vertx.ext.auth.jwt.JWTAuth
import io.vertx.ext.web.handler.JWTAuthHandler
import io.vertx.kotlin.core.json.json
import io.vertx.kotlin.core.json.obj
import io.vertx.kotlin.ext.auth.KeyStoreOptions
import io.vertx.kotlin.ext.auth.jwt.JWTAuthOptions
import io.vertx.kotlin.ext.auth.jwt.JWTOptions
import java.security.SecureRandom
import java.util.UUID
import javassist.util.proxy.FactoryHelper.writeFile




class InternalAPIVerticle : APIVerticle() {

    private val USER_FIELDS = "User.id AS `user.id`, User.username AS `user.username`, User.realname AS `user.realname`, User.email AS `user.email`, User.avatar AS `user.avatar`"
    private val CATEGORY_FIELDS = "Category.id AS `category.id`, Category.name AS `category.name`"
    private val CLIENT_ID = "790199984953-9ug0i2t89na28pc2sucogocusnugs87p.apps.googleusercontent.com"

    private lateinit var jwtProvider: JWTAuth

    private val srandom = SecureRandom()
    private val base64Decoder = Base64.getDecoder()

    private fun initRouter() {
        router.apply {

            // route("/account/*").handler(ResponseContentTypeHandler.create())
            // route("/account/*").handler(oauth2Handler)
            // route(HttpMethod.POST, "/account").handler(BodyHandler.create())
            // route(HttpMethod.POST, "/login").handler(BodyHandler.create())

            // paths that require authentication

            route().handler(BodyHandler.create())

            route().failureHandler { ctx ->
                when(ctx.failure()){
                    is com.github.mauricio.async.db.mysql.exceptions.MySQLException -> {
                        val error = ctx.failure()!!.message!!.split(" - ")
                        
                        ctx.response().setStatusCode(400)
                        if(error[1] == "#45000"){ // our own mysql error
                            ctx.response().setStatusMessage(error[2])
                        }
                        ctx.response().end()
                    }
                    is IndexOutOfBoundsException -> {
                        ctx.response().setStatusCode(400).end() //ctx.fail(400)
                    }
                    else -> {
                        if(ctx.failure() != null)
                            logger.error(ctx.failure().toString())
                        ctx.response().setStatusCode(500).end()
                    }
                }
            }

            // PROJECTS

            get("/projects/").handler { ctx ->
                query(ctx, """SELECT
                                Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                                $CATEGORY_FIELDS,
                                $USER_FIELDS
                            FROM Project, Category, User
                            WHERE Project.category = Category.id AND Project.user = User.id""") { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            get("/projects/:id").handler { ctx ->
                val idString = ctx.request().getParam("id")

                if (idString == "random") {
                    query(ctx, """SELECT
                                Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                                $CATEGORY_FIELDS,
                                $USER_FIELDS
                                FROM Project, Category, User
                                WHERE Project.category = Category.id AND Project.user = User.id AND Project.deleted = 0 AND Project.completed = 0
                                ORDER BY RAND() LIMIT 1;""") { ctx, res ->

                        val project = res.getRows()[0].unflatten()
                        ctx.response().endWithJson(project)
                    }
                } else {
                    val id = idString.toInt()
                    query(ctx, """SELECT
                                    Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                                    $CATEGORY_FIELDS,
                                    $USER_FIELDS
                                FROM Project, Category, User
                                WHERE Project.id = ? AND Project.category = Category.id AND Project.user = User.id""", id) { ctx, res ->

                        val project = res.getRows()[0].unflatten()
                        ctx.response().endWithJson(project)
                    }
                }
                //TODO ha nincs result 404
            }

            get("/projects/random/getByCategory/:categories").handler { ctx->
                val categories = ctx.request().getParam("categories").split(",")
                println(categories.joinToString(","))
                //TODO mysql inject

                query(ctx, """SELECT
                            Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                            $CATEGORY_FIELDS,
                            $USER_FIELDS
                            FROM Project, User, Category
                            WHERE Project.category = Category.id AND Project.user = User.id AND Project.deleted = 0 AND Project.completed = 0 AND FIND_IN_SET(Project.category, ?)
                            ORDER BY RAND() LIMIT 1""", categories.joinToString(","))
                { ctx, res ->
                    val project = res.getRows()[0].unflatten()
                    ctx.response().endWithJson(project)
                }
            }

            get("/projects/:id/donated").handler { ctx ->
                val idString = ctx.request().getParam("id")

                if (idString == "random") {
                    query(ctx, """SELECT project, -1 as 'user', CAST(SUM(amount) AS SIGNED) AS amount
                                FROM Donation
                                GROUP BY project
                            ORDER BY RAND() LIMIT 1;""") { ctx, res ->

                        val project = res.getRows()[0].unflatten()
                        ctx.response().endWithJson(project)
                    }
                } else {
                    val id = idString.toInt()
                    query(ctx, """SELECT project, -1 as 'user', CAST(SUM(amount) AS SIGNED) AS amount
                                FROM Donation
                                where project = ?
                                GROUP BY project""", id) { ctx, res ->

                        val project = res.getRows()[0].unflatten()
                        ctx.response().endWithJson(project)
                    }
                }
                //TODO ha nincs result 404
            }


            get("/projects/donatedby/myuser").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")

                query(ctx, """SELECT
                            Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                            $CATEGORY_FIELDS,
                            $USER_FIELDS
                            FROM Project, Donation, User, Category
                            WHERE Donation.project = Project.id AND Donation.user = ? AND Project.category = Category.id AND Project.user = User.id
                            GROUP BY Project.id""", user) { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            get("/projects/donatedby/:user").handler { ctx ->
                val user = ctx.request().getParam("user").toInt()
                query(ctx, """SELECT
                            Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                            $CATEGORY_FIELDS,
                            $USER_FIELDS
                            FROM Project, Donation, User, Category
                            WHERE Donation.project = Project.id AND Donation.user = ? AND Project.category = Category.id AND Project.user = User.id
                            GROUP BY Project.id""", user) { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            get("/projects/createdby/:user").handler { ctx ->
                val user = ctx.request().getParam("user").toInt()

                query(ctx, """SELECT
                            Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                            $CATEGORY_FIELDS,
                            $USER_FIELDS
                            FROM Project, User, Category
                            WHERE Project.category = Category.id AND Project.user = User.id AND Project.user = ?
                            """, user) { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            get("/projects/getByCategory/:categories").handler { ctx->
                val categories = ctx.request().getParam("categories").split(",")
                //TODO mysql inject

                query(ctx, """SELECT
                            Project.id, Project.name, Project.goal, Project.description, Project.description_long, Project.deadline, Project.deleted, Project.completed,
                            $CATEGORY_FIELDS,
                            $USER_FIELDS
                            FROM Project, User, Category
                            WHERE Project.category = Category.id AND Project.user = User.id AND FIND_IN_SET(Project.category, ?)""", categories.joinToString(","))
                { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            // add a new Project
            post("/projects").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val project = ctx.bodyAsJson
                val user = ctx.user().principal().getInteger("sub")

                update(ctx,
                    "INSERT INTO Project(name, category, goal, description, description_long, deadline, user) VALUE (?, ?, ?, ?, ?, ?, ?)",
                        project.getString("name"),
                        project.getInteger("category"),
                        project.getInteger("goal"),
                        project.getString("description"),
                        project.getString("description_long"),
                        project.getString("deadline"),
                        user
                ){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            delete("/projects/:id").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")
                val id = ctx.request().getParam("id").toInt()

                update(ctx, "UPDATE Project SET deleted = 1 WHERE id = ? AND Project.user = ?", id, user){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            // CATEGORIES

            get("/categories").handler { ctx ->
                query(ctx, "SELECT * FROM Category") { ctx, res ->
                    ctx.response().endWithJson(res.getRows())
                }
            }

            get("/categories/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()

                query(ctx, "SELECT * FROM Category WHERE id = ?", id) { ctx, res ->
                    ctx.response().endWithJson(res.getRows()[0])
                }
            }

            // USER

            put("/authenticate/login").handler { ctx ->
                val user = ctx.bodyAsJson

                val username = user.getString("username")
                val password = user.getString("password")

                query(ctx, "SELECT id, password, salt FROM User WHERE username = ?", username) { ctx, res ->
                    // TODO ha nincs ilyen user akkor hibat dob, ez nemtom mennyire jo
                    val data = res.getRows()[0]

                    if(PasswordManager.validatePassword(password, data.getString("salt"), data.getString("password"))){
                        val token = jwtProvider.generateToken(json {
                            obj("sub" to data.getInteger("id"), "username" to data.getString("username"))
                        }, JWTOptions())

                        ctx.response().end(token)
                    }else{
                        ctx.response().setStatusCode(401).end()
                    }
                }
            }

            post("/authenticate/google").handler { ctx ->
                val token = verifyGoogleToken(ctx.request().headers()["Authentication"])

                if(token != null){
                    println(token.subject)
                    println(token.subject.length)

                    query(ctx, "SELECT * FROM User WHERE google_sub = ?", token.subject) { ctx, res ->
                        if(res.rows.isNotEmpty()){
                            val data = res.rows[0]
                            val jwt = jwtProvider.generateToken(json {
                                obj("sub" to data.getInteger("id"), "username" to data.getString("username"))
                            }, JWTOptions())

                            ctx.response().end(jwt)
                        }else{
                            //query email -> update or inster -> return jwt
                        }
                    }
                }else{
                    ctx.fail(401)
                }

//                val user = ctx.bodyAsJson
//
//                val username = user.getString("username")
//                val password = user.getString("password")
//
//                query(ctx, "SELECT id, password, salt FROM User WHERE username = ?", username) { ctx, res ->
//                    // TODO ha nincs ilyen user akkor hibat dob, ez nemtom mennyire jo
//                    val data = res.getRows()[0]
//
//                    if (PasswordManager.validatePassword(password, data.getString("salt"), data.getString("password"))) {
//                        val token = jwtProvider.generateToken(json {
//                            obj("sub" to username, "id" to data.getInteger("id"))
//                        }, JWTOptions())
//
//                        ctx.response().end(token)
//                    } else {
//                        ctx.response().setStatusCode(401).end()
//                    }
//                }
            }

            post("/authenticate/register").handler { ctx ->
                val user = ctx.bodyAsJson

                val username = user.getString("username")
                val email = user.getString("email")
                val salt = PasswordManager.createSalt()
                val password = PasswordManager.createHash(user.getString("password"), salt)

                update(ctx, "INSERT INTO User(username, email, salt, password, reg_date) VALUE (?, ?, ?, ?, ?)",
                        username,
                        email,
                        salt,
                        password,
                        "missing date"){ ctx, res ->

                    ctx.response().endWithJson(res.toJson()) //TODO return jwt
                }
            }


            get("/users/myuser").handler(JWTAuthHandler.create(jwtProvider))
            get("/users/:id").handler { ctx ->
                val id = ctx.request().getParam("id")

                if(id == "myuser"){
                    val id = ctx.user().principal().getInteger("sub")

                    query(ctx, "SELECT   id, username, realname, email, reg_date, avatar, balance FROM User WHERE id = ?", id) { ctx, res ->
                        ctx.response().endWithJson(res.getRows()[0])
                    }
                }else{
                    query(ctx, "SELECT   id, username, realname, email, reg_date, avatar FROM User WHERE id = ?", id.toInt()) { ctx, res ->
                        ctx.response().endWithJson(res.getRows()[0])
                    }
                }
            }

            put("/users/update").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")
                val data = ctx.bodyAsJson
                val avatar = data.getString("avatar")

                saveAvatar(avatar).setHandler {res ->
                    if(res.succeeded()){
                        update(ctx, "UPDATE User SET User.avatar = ? WHERE User.id = ?", res.result(), user){ ctx, res ->
                            ctx.response().endWithJson(res.toJson())
                        }
                    }
                }
            }

            delete("/users/avatar").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")

                update(ctx, "UPDATE User SET User.avatar = null WHERE User.id = ?", user){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            get("/image/${config().getString("avatarFolder")}/:file").handler { ctx ->
                val file = ctx.request().getParam("file")

                if(file.indexOf("..") != -1)
                    ctx.fail(RuntimeException("illegal path"))

                ctx.response().sendFile("${config().getString("avatarFolder")}/$file")
            }


            // DONATION

            post("/donation").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val donation = ctx.getBodyAsJson()
                val user = ctx.user().principal().getInteger("sub")

                updateTransaction(ctx, 
                    """INSERT INTO Donation(project, user, amount) VALUE (?, ?, ?)""" to arrayOf<Any>(
                            donation.getInteger("project"),
                            user,
                            donation.getInteger("amount")),
                    """UPDATE User SET balance = balance - ? WHERE id = ?""" to arrayOf<Any>(
                            donation.getInteger("amount"),
                            user),
                    """INSERT INTO Progress(reward, user, count)
                        SELECT Reward.id, ?, 1 FROM Reward, Project WHERE Reward.category = Project.category AND Project.id = ?
                        ON DUPLICATE KEY UPDATE count = count + 1""" to arrayOf<Any>(
                            user,
                            donation.getInteger("project"))
                ){ ctx ->
                    // list the newly finished progresses (doesn't check category to the current donation
                    query(ctx, """SELECT Reward.name AS name, Reward.description AS description, Reward.category AS category, Reward.goal as goal, Reward.small_avatar as small_avatar, Reward.big_avatar as big_avatar
                        |         FROM Progress, Reward WHERE Progress.user = ? AND Progress.Reward = Reward.id AND
                        |         Progress.count = Reward.goal AND Progress.done = 0""".trimMargin(), donation.getInteger("user"))
                    { ctx, res ->
                        ctx.response().endWithJson(res.rows)
                        if(res.rows.isNotEmpty()){
                            //set progresses to done
                            update(ctx, "UPDATE Progress, Reward SET done = 1 WHERE Progress.user = ? AND Progress.Reward = Reward.id AND Progress.count = Reward.goal AND Progress.done = 0", donation.getInteger("user")){ ctx, res -> }
                        }
                    }
                }
            }

            get("/donation/myuser/:project").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")
                val project = ctx.request().getParam("project").toInt()

                query(ctx, """SELECT
                            project, user, CAST(sum(amount) AS SIGNED) as amount
                            FROM Donation
                            WHERE user = ? and project = ?
                            GROUP BY project, user""", user, project)
                { ctx, res ->
                    ctx.response().endWithJson(res.getRows()[0].unflatten())
                }
            }

            // MESSAGE

            get("/messages/:id").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")
                val id = ctx.request().getParam("id")

                if(id == "myuser"){
                    query(ctx, """
                                    SELECT Message.id, Message.receiver_id, Message.subject, Message.message_body, Message.send_date, Message.parent_id, Message.receiver_read,
                                    $USER_FIELDS
                                    FROM Message, User
                                    WHERE (Message.receiver_id = ? OR Message.sender_id = ?) AND Message.sender_id = User.id AND
                                        Message.id not in (SELECT m.parent_id FROM Message m WHERE m.parent_id is not null AND (m.receiver_id = ? OR m.sender_id = ?))
                                    ORDER BY Message.id DESC;
                                """, user, user, user, user) { ctx, res ->
                        ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                    }
                }
                else {
                    query(ctx, """
                                    SELECT Message.id, Message.receiver_id, Message.subject, Message.message_body, Message.send_date, Message.parent_id, Message.receiver_read,
                                    $USER_FIELDS
                                    FROM Message, User
                                    WHERE (Message.receiver_id = ? OR Message.sender_id = ?) AND Message.sender_id = User.id AND Message.id = ?
                                """, user, user, id) { ctx, res ->
                        ctx.response().endWithJson(res.getRows()[0].unflatten())
                    }
                }
            }

            put("/messages/:id/read").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                val user = ctx.user().principal().getInteger("sub")

                update(ctx, "UPDATE Message SET Message.receiver_read = 1 WHERE Message.receiver_id = ? AND Message.id = ?", user, id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            put("/messages/:id/unread").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                val user = ctx.user().principal().getInteger("sub")

                update(ctx, "UPDATE Message SET Message.receiver_read = 0 WHERE Message.receiver_id = ? AND Message.id = ?", user, id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            post("/messages").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val message = ctx.getBodyAsJson()
                val user = ctx.user().principal().getInteger("sub")

                //TODO Stringekben ne lehessen sql injection
                try {
                    update(ctx, "INSERT INTO Message(sender_id, receiver_id, subject, message_body, send_date, parent_id) VALUE (?, ?, ?, ?, ?, ?)",
                            user,
                            message.getInteger("receiver_id"),
                            message.getString("subject"),
                            message.getString("message_body"),
                            message.getString("send_date"),
                            message.getInteger("parent_id")){ ctx, res ->

                        ctx.response().endWithJson(res.toJson())
                    }
                } catch (e: ClassCastException) {
                    update(ctx, "INSERT INTO Message(sender_id, receiver_id, subject, message_body, send_date, parent_id) VALUE (?, ?, ?, ?, ?, ?)",
                            user,
                            message.getInteger("receiver_id"),
                            message.getString("subject"),
                            message.getString("message_body"),
                            message.getString("send_date"),
                            null){ ctx, res ->

                        ctx.response().endWithJson(res.toJson())
                    }
                }
            }

            delete("/messages/:id").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val id = ctx.request().getParam("id").toInt()
                val user = ctx.user().principal().getInteger("sub")

                update(ctx, "DELETE FROM Message WHERE receiver_id = ?  AND id = ?",user, id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            // REWARD

            get("/rewards/:id").handler { ctx ->
                val id = ctx.request().getParam("id").toInt()

                query(ctx, """SELECT
                            Reward.id, Reward.name, Reward.goal, Reward.description, Reward.small_avatar, Reward.big_avatar,
                            $CATEGORY_FIELDS
                            FROM Reward, Category
                            WHERE Reward.category = Category.id AND Reward.id = ?""", id)
                { ctx, res ->
                    ctx.response().endWithJson(res.getRows()[0].unflatten())
                }
            }

            get("/rewards/").handler { ctx ->

                query(ctx, """SELECT
                            Reward.id, Reward.name, Reward.goal, Reward.description, Reward.small_avatar, Reward.big_avatar,
                            $CATEGORY_FIELDS
                            FROM Reward, Category
                            WHERE Reward.category = Category.id
                            """) { ctx, res ->
                    ctx.response().endWithJson(res.getRows().map{ it.unflatten() })
                }
            }

            post("/rewards").handler { ctx ->
                val reward = ctx.getBodyAsJson()
                
                //TODO Stringekben ne lehessen sql injection
                update(ctx, "INSERT INTO Reward(name, description, category, goal) VALUE (?, ?, ?, ?)",
                    reward.getString("name"),
                    reward.getString("description"),
                    reward.getInteger("category"),
                    reward.getInteger("goal")){ ctx, res ->

                    ctx.response().endWithJson(res.toJson())            
                }
            }

            delete("/rewards/:id").handler { ctx -> 
                val id = ctx.request().getParam("id").toInt()

                update(ctx, "DELETE FROM Reward WHERE id = ?", id){ ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }

            get("/progress/:reward/myuser").handler(JWTAuthHandler.create(jwtProvider))
            get("/progress/:reward/myuser").handler { ctx ->
                val user = ctx.user().principal().getInteger("sub")
                val reward = ctx.request().getParam("reward").toInt()

                query(ctx, """SELECT
                    Progress.count
                    FROM Reward, Progress, Category
                    WHERE Reward.category = Category.id AND Reward.id = Progress.reward AND Reward.id = ? AND Progress.user = ?""", reward, user)
                { ctx, res ->
                    ctx.response().endWithJson(res.getRows()[0].unflatten())
                }
            }

            post("/purchase").handler(JWTAuthHandler.create(jwtProvider)).handler { ctx ->
                val purchase = ctx.getBodyAsJson()
                val user = ctx.user().principal().getInteger("sub")

                //TODO Stringekben ne lehessen sql injection
                update(ctx, "UPDATE User SET User.balance = User.balance + ? WHERE User.id = ?",
                        purchase.getInteger("amount"),
                        user)
                { ctx, res ->
                    ctx.response().endWithJson(res.toJson())
                }
            }
        }
    }

    private fun saveAvatar(avatar: String): Future<String> {
        val future = Future.future<String>()

        val uuid = UUID.randomUUID()
        val file = "${config().getString("avatarFolder")}/$uuid.png"
        val img = base64Decoder.decode(avatar)

        logger.info(file)

        vertx.fileSystem().writeFile(file, Buffer.buffer(img)) { handler ->
            if (handler.succeeded()) {
                future.complete(file)
                logger.info("img write successful")
            } else {
                future.fail(handler.cause())
                logger.error("Error while writing in file: " + handler.cause().message)
            }
        }

        return future
    }

    override fun start(fut: Future<Void>?) {
        super.start(fut)

        jwtProvider = JWTAuth.create(vertx, JWTAuthOptions(keyStore = KeyStoreOptions(
            path = config().getJsonObject("jwt").getString("path"),
            password = config().getJsonObject("jwt").getString("password")
        )))

        initRouter()
    }

    private val googleIdTokenVerifier = GoogleIdTokenVerifier.Builder(NetHttpTransport(), JacksonFactory())
            // Specify the CLIENT_ID of the app that accesses the backend:
            .setAudience(Collections.singletonList(CLIENT_ID))
            // Or, if multiple clients access the backend:
            //.setAudience(Arrays.asList(CLIENT_ID_1, CLIENT_ID_2, CLIENT_ID_3))
            .build()

    private fun verifyGoogleToken(token: String?): GoogleIdToken.Payload? {
        if(token == null)
            return null

        val idToken = googleIdTokenVerifier.verify(token)
        println(idToken)
        if (idToken != null) {
            val payload = idToken.payload
            println(payload)
            return payload
        } else {
            return null
        }
    }
}