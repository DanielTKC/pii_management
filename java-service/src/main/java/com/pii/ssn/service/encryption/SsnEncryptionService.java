package com.pii.ssn.service.encryption;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Service for encrypting and decrypting SSNs using AES-256-GCM
 */
@Service
public class SsnEncryptionService {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final int GCM_TAG_LENGTH = 128; // bits
    private static final int GCM_IV_LENGTH = 12; // bytes (96 bits, recommended for GCM)

    private final SecretKey secretKey;
    private final SecureRandom secureRandom;

    /**
     * Constructor - works for both testing and Spring dependency injection
     *
     * @param base64Key Base64-encoded 32-byte AES-256 key
     */
    public SsnEncryptionService(@Value("${encryption.key:#{null}}") String base64Key) {
        if (base64Key == null || base64Key.trim().isEmpty()) {
            throw new IllegalArgumentException("Encryption key cannot be null or empty");
        }

        try {
            byte[] decodedKey = Base64.getDecoder().decode(base64Key);

            if (decodedKey.length != 32) {
                throw new IllegalArgumentException("Encryption key must be 32 bytes (256 bits) for AES-256");
            }

            this.secretKey = new SecretKeySpec(decodedKey, "AES");
            this.secureRandom = new SecureRandom();
        } catch (IllegalArgumentException e) {
            if (e.getMessage().contains("Illegal base64")) {
                throw new IllegalArgumentException("Encryption key must be valid Base64 encoded", e);
            }
            throw e;
        }
    }

    /**
     * Encrypts an SSN using AES-256-GCM
     *
     * @param ssn Plaintext SSN
     * @return Base64-encoded encrypted SSN (IV + ciphertext + auth tag)
     */
    public String encrypt(String ssn) {
        if (ssn == null || ssn.trim().isEmpty()) {
            throw new IllegalArgumentException("SSN cannot be null or empty");
        }

        try {
            // Generate random IV for each encryption (ensures different ciphertext for same plaintext)
            byte[] iv = new byte[GCM_IV_LENGTH];
            secureRandom.nextBytes(iv);

            // Initialize cipher
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmSpec);

            // Encrypt
            byte[] ciphertext = cipher.doFinal(ssn.getBytes());

            // Combine IV + ciphertext (GCM auth tag is included in ciphertext by Java)
            byte[] encrypted = new byte[GCM_IV_LENGTH + ciphertext.length];
            System.arraycopy(iv, 0, encrypted, 0, GCM_IV_LENGTH);
            System.arraycopy(ciphertext, 0, encrypted, GCM_IV_LENGTH, ciphertext.length);

            // Return Base64 encoded
            return Base64.getEncoder().encodeToString(encrypted);

        } catch (Exception e) {
            throw new RuntimeException("Failed to encrypt SSN", e);
        }
    }

    /**
     * Decrypts an encrypted SSN
     *
     * @param encryptedSsn Base64-encoded encrypted SSN (IV + ciphertext + auth
     * tag)
     * @return Plaintext SSN
     */
    public String decrypt(String encryptedSsn) {
        if (encryptedSsn == null || encryptedSsn.trim().isEmpty()) {
            throw new IllegalArgumentException("Encrypted SSN cannot be null or empty");
        }

        try {
            // Decode from Base64
            byte[] encrypted = Base64.getDecoder().decode(encryptedSsn);

            // Extract IV and ciphertext
            byte[] iv = new byte[GCM_IV_LENGTH];

            byte[] ciphertext = new byte[encrypted.length - GCM_IV_LENGTH];

            System.arraycopy(encrypted, 0, iv, 0, GCM_IV_LENGTH);
            System.arraycopy(encrypted, GCM_IV_LENGTH, ciphertext, 0, ciphertext.length);

            // Initialize cipher
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec);

            // Decrypt
            byte[] plaintext = cipher.doFinal(ciphertext);

            return new String(plaintext);

        } catch (Exception e) {
            throw new RuntimeException("Failed to decrypt SSN - data may be corrupted or tampered", e);
        }
    }

    /**
     * Extracts the last four digits from an SSN for display purposes
     *
     * @param ssn SSN in any format (with or without dashes)
     * @return Last four digits
     */
    public String extractLastFour(String ssn) {
        if (ssn == null || ssn.trim().isEmpty()) {
            throw new IllegalArgumentException("SSN cannot be null or empty");
        }

        String digitsOnly = ssn.replaceAll("\\D", "");

        if (digitsOnly.length() < 4) {
            throw new IllegalArgumentException("SSN must contain at least 4 digits");
        }

        // Return last 4 digits
        return digitsOnly.substring(digitsOnly.length() - 4);
    }
}
