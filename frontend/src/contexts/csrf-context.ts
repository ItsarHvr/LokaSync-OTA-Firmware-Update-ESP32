import { createContext, useContext } from "react";

export interface CSRFContextType {
  getToken: () => string;
  validateToken: (token: string) => boolean;
  refreshToken: () => string;
}

export const CSRFContext = createContext<CSRFContextType | undefined>(
  undefined,
);

export const useCSRF = () => {
  const context = useContext(CSRFContext);
  if (context === undefined) {
    throw new Error("useCSRF must be used within a CSRFProvider");
  }
  return context;
};
