import type { ReactNode } from "react";
import { CSRFContext, type CSRFContextType } from "./csrf-context";
import {
  getCSRFToken,
  validateCSRFToken,
  refreshCSRFToken,
} from "../utils/csrf";

interface CSRFProviderProps {
  children: ReactNode;
}

export const CSRFProvider = ({ children }: CSRFProviderProps) => {
  // Create context value with functions from csrf utility
  const value: CSRFContextType = {
    getToken: getCSRFToken,
    validateToken: validateCSRFToken,
    refreshToken: refreshCSRFToken,
  };

  return <CSRFContext.Provider value={value}>{children}</CSRFContext.Provider>;
};
