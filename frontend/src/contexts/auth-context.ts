// filepath: d:\Kuliah\Semester6\09_Proyek-Kekhususan\lokasync-web\frontend\src\contexts\auth-context.ts
import { createContext, useContext } from "react";
import type { User } from "../types";

export interface AuthContextType {
  currentUser: User | null;
  isLoading: boolean;
  register: (
    email: string,
    password: string,
    displayName: string,
  ) => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updateUserProfile: (displayName: string) => Promise<void>;
}

export const AuthContext = createContext<AuthContextType | undefined>(
  undefined,
);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
