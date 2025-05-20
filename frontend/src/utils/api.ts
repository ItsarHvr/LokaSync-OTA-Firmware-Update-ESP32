// API utility functions for LokaSync application
import { auth } from "../firebase";
import { getCSRFToken, refreshCSRFToken } from "./csrf";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api/v1";

// Helper function to get the current user's ID token
export const getIdToken = async (): Promise<string | null> => {
  const currentUser = auth.currentUser;
  if (!currentUser) {
    return null;
  }

  try {
    return await currentUser.getIdToken();
  } catch (error) {
    console.error("Error getting ID token:", error);
    return null;
  }
};

// Generic fetch function with authentication
export const fetchWithAuth = async <T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> => {
  const token = await getIdToken();
  const csrfToken = getCSRFToken();

  // Set default method to GET if not provided
  const method = options.method || "GET";
  
  // Only include CSRF token for non-GET requests
  const isModifyingRequest = method !== "GET";

  // Check if the request body is FormData
  const isFormData = options.body instanceof FormData;

  const headers = {
    // Only set Content-Type for non-FormData requests
    ...(isFormData ? {} : { "Content-Type": "application/json" }),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(isModifyingRequest ? { "X-CSRF-Token": csrfToken } : {}),
    ...options.headers,
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      method, // Use the explicitly set method
      headers,
      credentials: "include", // Include credentials for cross-origin requests
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      const errorMessage =
        errorData.message || `Request failed with status ${response.status}`;
      throw new Error(errorMessage);
    }

    // For successful non-GET requests, refresh the CSRF token after the operation
    if (isModifyingRequest) {
      refreshCSRFToken();
    }

    return response.json();
  } catch (error: unknown) {
    // Log the error for debugging
    console.error(`API Error (${endpoint}):`, error);

    // Rethrow with a more specific message if possible
    if (error instanceof Error) {
      throw new Error(error.message);
    }
    throw new Error("Network error occurred");
  }
};

// Function to create query params string from an object
export const createQueryParams = (params: Record<string, unknown>): string => {
  const validParams = Object.entries(params)
    .filter(
      ([, value]) => value !== undefined && value !== null && value !== "",
    )
    .map(
      ([key, value]) =>
        `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`,
    )
    .join("&");

  return validParams ? `?${validParams}` : "";
};
