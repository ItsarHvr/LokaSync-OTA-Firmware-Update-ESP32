import { useLocation } from "react-router-dom";

const Footer = () => {
  const location = useLocation();

  // Determine if we should show the footer (not on auth pages)
  const isAuthPage = ["/login", "/register", "/forgot-password"].includes(
    location.pathname,
  );
  if (isAuthPage) return null;

  return (
    <footer className="bg-white border-t border-lokasync-border py-6 mt-auto">
      <div className="lokasync-container">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="mb-4 md:mb-0">
            <p className="text-sm text-gray-600">
              &copy; {new Date().getFullYear()} LokaSync - All rights reserved.
            </p>
          </div>

          <div className="flex space-x-4">
            <a
              href="#"
              className="text-sm text-gray-600 hover:text-lokasync-primary"
            >
              Privacy Policy
            </a>
            <a
              href="#"
              className="text-sm text-gray-600 hover:text-lokasync-primary"
            >
              Terms of Service
            </a>
            <a
              href="#"
              className="text-sm text-gray-600 hover:text-lokasync-primary"
            >
              Contact Us
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
