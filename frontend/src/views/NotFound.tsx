import { Link } from "react-router-dom";
import { useEffect } from "react";
import Button from "../components/ui/Button";

const NotFound = () => {
  // Set document title
  useEffect(() => {
    document.title = "LokaSync | Page Not Found";
  }, []);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-lokasync-light-green p-4">
      <div className="lokasync-card max-w-md w-full text-center">
        <div className="mb-6">
          <img
            src="/lokasync_logo.png"
            alt="LokaSync Logo"
            className="h-20 w-20 mx-auto mb-4"
          />
        </div>
        <h1 className="text-6xl font-bold text-lokasync-accent mb-4">404</h1>
        <h2 className="text-2xl font-medium mb-6">Page not found</h2>
        <p className="text-gray-600 mb-8">
          The page you are looking for doesn't exist or has been moved.
        </p>
        <Link to="/dashboard" className="block">
          <Button type="button" size="lg" fullWidth>
            Return to Dashboard
          </Button>
        </Link>
      </div>
    </div>
  );
};

export default NotFound;
