import { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../../contexts";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const { currentUser, logout } = useAuth();
  const location = useLocation();

  // Close menu when location changes (navigating to another page)
  useEffect(() => {
    setIsMenuOpen(false);
    setIsProfileMenuOpen(false);
  }, [location]);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  const toggleProfileMenu = () => {
    setIsProfileMenuOpen(!isProfileMenuOpen);
  };

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error("Failed to log out", error);
    }
  };

  // Determine if we should show the header (not on auth pages)
  const isAuthPage = ["/login", "/register", "/forgot-password"].includes(
    location.pathname,
  );
  if (isAuthPage) return null;

  return (
    <header className="bg-white border-b border-lokasync-border shadow-sm">
      <div className="lokasync-container">
        <nav className="flex items-center justify-between h-16">
          {/* Logo */}{" "}
          <div className="flex items-center">
            {" "}
            <Link
              to="/dashboard"
              className="flex items-center text-lokasync-accent font-bold text-xl"
            >
              <img
                src="/lokasync_logo.png"
                alt="LokaSync Logo"
                className="h-8 w-8 mr-2"
              />
              LokaSync
            </Link>
          </div>
          {/* Mobile Menu Button */}
          <div className="md:hidden">
            <button
              onClick={toggleMenu}
              className="text-gray-600 hover:text-lokasync-primary focus:outline-none"
              aria-label={isMenuOpen ? "Close menu" : "Open menu"}
            >
              {isMenuOpen ? (
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              ) : (
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              )}
            </button>
          </div>
          {/* Desktop Navigation Links */}
          <div className="hidden md:flex items-center space-x-6">
            <Link
              to="/dashboard"
              className={`nav-link px-3 py-2 rounded transition-colors duration-150 ${
                location.pathname.includes("/dashboard")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600 hover:text-lokasync-primary"
              }`}
            >
              Dashboard
            </Link>
            <Link
              to="/monitoring"
              className={`nav-link px-3 py-2 rounded transition-colors duration-150 ${
                location.pathname.includes("/monitoring")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600 hover:text-lokasync-primary"
              }`}
            >
              Monitoring
            </Link>
            <Link
              to="/log"
              className={`nav-link px-3 py-2 rounded transition-colors duration-150 ${
                location.pathname.includes("/log")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600 hover:text-lokasync-primary"
              }`}
            >
              Update Log
            </Link>

            {/* Profile Menu */}
            {currentUser && (
              <div className="relative">
                <button
                  onClick={toggleProfileMenu}
                  className="flex items-center text-gray-600 hover:text-lokasync-primary focus:outline-none"
                >
                  <span className="mr-1">
                    {currentUser.displayName || currentUser.email}
                  </span>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19 9l-7 7-7-7"
                    />
                  </svg>
                </button>

                {isProfileMenuOpen && (
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10 border border-lokasync-border">
                    <Link
                      to="/profile"
                      className="block px-4 py-2 text-sm text-gray-700 hover:bg-lokasync-light-green"
                    >
                      Profile
                    </Link>
                    <button
                      onClick={handleLogout}
                      className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-lokasync-light-green"
                    >
                      Logout
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </nav>

        {/* Mobile Navigation Links */}
        {isMenuOpen && (
          <div className="md:hidden bg-white py-2 pb-4">
            <Link
              to="/dashboard"
              className={`nav-link block px-4 py-2 rounded ${
                location.pathname.includes("/dashboard")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600"
              }`}
            >
              Dashboard
            </Link>
            <Link
              to="/monitoring"
              className={`nav-link block px-4 py-2 rounded ${
                location.pathname.includes("/monitoring")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600"
              }`}
            >
              Monitoring
            </Link>
            <Link
              to="/log"
              className={`nav-link block px-4 py-2 rounded ${
                location.pathname.includes("/log")
                  ? "text-lokasync-primary font-medium active"
                  : "text-gray-600"
              }`}
            >
              Update Log
            </Link>

            {currentUser && (
              <>
                <Link
                  to="/profile"
                  className="nav-link block px-4 py-2 text-gray-600 hover:text-lokasync-primary"
                >
                  Profile
                </Link>
                <button
                  onClick={handleLogout}
                  className="nav-link block w-full text-left px-4 py-2 text-gray-600 hover:text-lokasync-primary"
                >
                  Logout
                </button>
              </>
            )}
          </div>
        )}
      </div>
    </header>
  );
};

export default Header;
