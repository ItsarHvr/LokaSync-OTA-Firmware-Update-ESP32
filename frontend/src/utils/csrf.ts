/**
 * CSRF Protection Utility
 * Provides functions to generate, validate and manage CSRF tokens
 * for protecting forms against Cross-Site Request Forgery attacks
 */

// Key for storing CSRF token in sessionStorage
const CSRF_TOKEN_KEY = import.meta.env.VITE_CSRF_TOKEN || "lokasync_csrf_token";

/**
 * Generates a secure random token
 * @returns A random string to be used as CSRF token
 */
export const generateCSRFToken = (): string => {
  // Create a random array of 32 bytes
  const randomValues = new Uint8Array(32);
  window.crypto.getRandomValues(randomValues);

  // Convert to a base64 string and remove non-alphanumeric chars for cleaner tokens
  return btoa(String.fromCharCode(...randomValues))
    .replace(/[+/=]/g, "")
    .substring(0, 32);
};

/**
 * Stores the CSRF token in sessionStorage
 * Using sessionStorage ensures the token is valid only for the current session
 * @param token The CSRF token to store
 */
export const storeCSRFToken = (token: string): void => {
  sessionStorage.setItem(CSRF_TOKEN_KEY, token);
};

/**
 * Retrieves the stored CSRF token
 * @returns The stored CSRF token or null if not found
 */
export const getStoredCSRFToken = (): string | null => {
  return sessionStorage.getItem(CSRF_TOKEN_KEY);
};

/**
 * Gets the current CSRF token or generates a new one if none exists
 * @returns A CSRF token
 */
export const getCSRFToken = (): string => {
  let token = getStoredCSRFToken();

  if (!token) {
    token = generateCSRFToken();
    storeCSRFToken(token);
  }

  return token;
};

/**
 * Validates if the provided token matches the stored token
 * @param token The token to validate
 * @returns True if the token is valid, false otherwise
 */
export const validateCSRFToken = (token: string): boolean => {
  const storedToken = getStoredCSRFToken();
  return !!storedToken && token === storedToken;
};

/**
 * Refreshes the CSRF token by generating a new one
 * This should be called after a successful form submission for added security
 * @returns The new CSRF token
 */
export const refreshCSRFToken = (): string => {
  const newToken = generateCSRFToken();
  storeCSRFToken(newToken);
  return newToken;
};

/**
 * Creates a hidden input element for a CSRF token
 * Note: This function has been moved to the CSRFForm component
 * and is kept here for reference only
 */
// JSX implementation removed to avoid compilation errors
