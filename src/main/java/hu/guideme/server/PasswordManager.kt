package hu.guideme.server

import java.nio.charset.Charset
import java.security.SecureRandom
import java.util.*
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import javax.swing.Box
import kotlin.experimental.xor

object PasswordManager {
    private val PBKDF2_ALGORITHM = "PBKDF2WithHmacSHA1"

    // The change of the following constants will break existing hashes
    private const val SALT_BYTES = 24
    private const val HASH_BYTES = 24
    private const val PBKDF2_ITERATIONS = 1000

    private val random = SecureRandom()
    private val base64Encoder = Base64.getEncoder()
    private val base64Decoder = Base64.getDecoder()

    /**
     * Generates new random salt with length of SALT_BYTES
     */
    fun createSalt(): String{
        val salt = ByteArray(SALT_BYTES)
        random.nextBytes(salt)
        return base64Encoder.encodeToString(salt)
    }

    /**
     * Returns PBKDF2 hash of the password salted with salt.
     *
     * @param   password    the password to hash
     * @param   salt        the salt to use
     * @return              a salted PBKDF2 hash of the password
     */
    fun createHash(password: String, salt: String): String {
        val hash = encodedPbkdf2(password.toCharArray(), base64Decoder.decode(salt), PBKDF2_ITERATIONS, HASH_BYTES)
        return hash
    }

    /**
     * Validates a password using a hash.
     *
     * @param   password    the password to check
     * @param   salt        the salt to use
     * @param   goodHash    the stored hash
     * @return              true if the password is correct, false if not
     */
    fun validatePassword(password: String, salt: String, goodHash: String): Boolean {
        val testHash = pbkdf2(password.toCharArray(), base64Decoder.decode(salt), PBKDF2_ITERATIONS, HASH_BYTES)

        return slowEquals(base64Decoder.decode(goodHash), testHash)
    }

    /**
     * Compares two byte arrays in length-constant time. This comparison method
     * is used so that password hashes cannot be extracted from an on-line
     * system using a timing attack and then attacked off-line.
     *
     * @param   a       the first byte array
     * @param   b       the second byte array
     * @return          true if both byte arrays are the same, false if not
     */
    private fun slowEquals(a: ByteArray, b: ByteArray): Boolean {
        var diff = a.size xor b.size
        var i = 0
        while (i < a.size && i < b.size) {
            diff = diff or ((a[i] xor b[i]).toInt())
            i++
        }
        return diff == 0
    }

    /**
     * Computes the PBKDF2 hash of a password.
     *
     * @param   password    the password to hash.
     * @param   salt        the salt
     * @param   iterations  the iteration count (slowness factor)
     * @param   bytes       the length of the hash to compute in bytes
     * @return              the base64 encoded PBDKF2 hash of the password
     */
    private fun encodedPbkdf2(password: CharArray, salt: ByteArray, iterations: Int, bytes: Int): String {
        return base64Encoder.encodeToString(pbkdf2(password, salt, iterations, bytes))
    }

    /**
     * Computes the PBKDF2 hash of a password.
     *
     * @param   password    the password to hash.
     * @param   salt        the salt
     * @param   iterations  the iteration count (slowness factor)
     * @param   bytes       the length of the hash to compute in bytes
     * @return              the PBDKF2 hash of the password
     */
    private fun pbkdf2(password: CharArray, salt: ByteArray, iterations: Int, bytes: Int): ByteArray {
        val spec = PBEKeySpec(password, salt, iterations, bytes * 8)
        val skf = SecretKeyFactory.getInstance(PBKDF2_ALGORITHM)
        return skf.generateSecret(spec).encoded
    }

}
