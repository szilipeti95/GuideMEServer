package hu.guideme.server

import org.slf4j.LoggerFactory
import java.io.FileInputStream
import java.util.*
import io.vertx.core.json.*
import java.io.File
import io.vertx.core.Vertx
import io.vertx.core.DeploymentOptions

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

//        val hibakStatement = conn.prepareStatement("SELECT hibajelentes.*, COUNT(hozzaszolas.id)
// AS chsz FROM hibajelentes LEFT JOIN hozzaszolas ON hozzaszolas.hibajelentes = hibajelentes.id 
// GROUP BY hibajelentes.id")
//        http.get("/") {
//            val model = HashMap<String, Any>()
//
//            val r = hibakStatement.executeQuery()
//            val hibaList = LinkedList<Hibajelentes>()
//            val chsz = LinkedList<Int>()
//            while(r.next()) {
//                hibaList.add(Hibajelentes(
//                        r.getInt("id"),
//                        r.getDate("datum"),
//                        r.getString("cim"),
//                        r.getString("leiras"),
//                        r.getBoolean("statusz"),
//                        getFelhasznalo(r.getString("letrehozo")),
//                        Szerepkor(r.getString("felelos"))))
//                chsz.add(r.getInt("chsz"))
//            }
//            model["hibak"] = hibaList
//            model["chsz"] = chsz
//
//            render(model, "issue_list.vsl")
//        }

//
//        val json = """[ { "id": 1, "name": "Asd1", "category": { "id": 0, "name": "cat1" },
//  "goal": 999, "description": "desc1", "descriptionLong": "description", "deadline": "Dec 24,
//  2017, 10:44:22 AM", "user": { "id": 0, "username": "asd", "realName": "Asd Janos", "email":
//  "asd@asd", "regDate": "Dec 24, 2017, 10:44:22 AM", "avatar": "null" } }, { "id": 2, "name":
//  "Asd2", "category": { "id": 0, "name": "cat1" }, "goal": 999, "description": "desc2",
//  "descriptionLong": "description", "deadline": "Dec 24, 2017, 10:44:22 AM", "user": {
    //  "id": 0, "username": "asd", "realName": "Asd Janos", "email": "asd@asd", "regDate":
    //  "Dec 24, 2017, 10:44:22 AM", "avatar": "null" } }, { "id": 4, "name": "Asd3", "category":
    //  { "id": 0, "name": "cat1" }, "goal": 999, "description": "desc222", "descriptionLong":
    //  "description", "deadline": "Dec 24, 2017, 10:44:22 AM", "user": { "id": 0, "username": "asd",
    //  "realName": "Asd Janos", "email": "asd@asd", "regDate": "Dec 24, 2017, 10:44:22 AM",
    //  "avatar": "null" } } ]"""
//
//        val r = gson.fromJson(json)
//        println(gson.fromJson(r.result!!, Error::class.java) == Error("asd", 2))
    }
}