import { lazy, Suspense } from "react";
import type React from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "../contexts";

// Lazy load page components
const Login = lazy(() => import("../views/auth/Login"));
const Register = lazy(() => import("../views/auth/Register"));
const ForgotPassword = lazy(() => import("../views/auth/ForgotPassword"));
const Dashboard = lazy(() => import("../views/dashboard/Dashboard"));
const AddFirmware = lazy(() => import("../views/firmware/AddFirmware"));
const EditFirmware = lazy(() => import("../views/firmware/EditFirmware"));
const Monitoring = lazy(() => import("../views/monitoring/Monitoring"));
const LogPage = lazy(() => import("../views/log/LogPage"));
const Profile = lazy(() => import("../views/profile/Profile"));
const NotFound = lazy(() => import("../views/NotFound"));

// Loading component for suspense fallback
const Loading = () => (
  <div className="flex items-center justify-center min-h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-lokasync-primary"></div>
  </div>
);

// Protected route component
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { currentUser, isLoading } = useAuth();

  if (isLoading) {
    return <Loading />;
  }

  if (!currentUser) {
    return <Navigate to="/login" />;
  }

  return children;
};

// Public route component (accessible only when not logged in)
const PublicRoute = ({ children }: { children: React.ReactElement }) => {
  const { currentUser, isLoading } = useAuth();

  if (isLoading) {
    return <Loading />;
  }

  if (currentUser) {
    return <Navigate to="/dashboard" />;
  }

  return children;
};

const AppRoutes = () => {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        {/* Public routes (only when not logged in) */}
        <Route
          path="/login"
          element={
            <PublicRoute>
              <Login />
            </PublicRoute>
          }
        />
        <Route
          path="/register"
          element={
            <PublicRoute>
              <Register />
            </PublicRoute>
          }
        />
        <Route
          path="/forgot-password"
          element={
            <PublicRoute>
              <ForgotPassword />
            </PublicRoute>
          }
        />

        {/* Protected routes (only when logged in) */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/firmware/add"
          element={
            <ProtectedRoute>
              <AddFirmware />
            </ProtectedRoute>
          }
        />
        <Route
          path="/firmware/edit/:nodeName"
          element={
            <ProtectedRoute>
              <EditFirmware />
            </ProtectedRoute>
          }
        />
        <Route
          path="/monitoring"
          element={
            <ProtectedRoute>
              <Monitoring />
            </ProtectedRoute>
          }
        />
        <Route
          path="/log"
          element={
            <ProtectedRoute>
              <LogPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />

        {/* Redirect from root to dashboard or login */}
        <Route path="/" element={<Navigate to="/dashboard" replace />} />

        {/* 404 page */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Suspense>
  );
};

export default AppRoutes;
