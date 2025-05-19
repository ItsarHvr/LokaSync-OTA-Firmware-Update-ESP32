import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Input from "../../components/ui/Input";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import PasswordInput from "../../components/ui/PasswordInput";
import { useAuth } from "../../contexts";
import { isValidEmail } from "../../utils/validation";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const { login } = useAuth();

  // Set document title
  useEffect(() => {
    document.title = "LokaSync | Login";
  }, []);

  const validateForm = (): boolean => {
    let isValid = true;

    // Reset errors
    setEmailError("");
    setPasswordError("");

    // Validate email
    if (!email) {
      setEmailError("Email is required");
      isValid = false;
    } else if (!isValidEmail(email)) {
      setEmailError("Please enter a valid email address");
      isValid = false;
    }

    // Validate password
    if (!password) {
      setPasswordError("Password is required");
      isValid = false;
    }

    return isValid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    try {
      setError("");
      setIsLoading(true);
      await login(email, password);
    } catch (err: unknown) {
      if (err instanceof Error) {
        // Improve error message for invalid credentials
        if (
          err.message.includes("auth/invalid-credential") ||
          err.message.includes("auth/wrong-password") ||
          err.message.includes("auth/user-not-found")
        ) {
          setError("Invalid username/password");
        } else {
          setError(err.message);
        }
      } else {
        setError("Failed to log in");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="auth-form-container">
      <div className="auth-form">
        <div className="text-center mb-6">
          <img
            src="/lokasync_logo.png"
            alt="LokaSync Logo"
            className="h-20 w-20 mx-auto mb-4"
          />
          <h1 className="text-3xl font-bold text-lokasync-accent">
            Sign In to Your Account
          </h1>
          <p className="text-gray-600 mt-2">Welcome back to LokaSync</p>
        </div>

        {error && (
          <Alert type="error" message={error} onClose={() => setError("")} />
        )}

        <CSRFForm onSubmit={handleSubmit}>
          <Input
            label="Email Address"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter your email"
            error={emailError}
            required
            autoFocus
          />

          <PasswordInput
            label="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            error={passwordError}
            required
          />

          <div className="flex items-center justify-end mb-4">
            <Link
              to="/forgot-password"
              className="text-sm text-lokasync-primary hover:text-lokasync-secondary"
            >
              Forgot Password?
            </Link>
          </div>

          <Button
            type="submit"
            fullWidth
            size="lg"
            isLoading={isLoading}
            disabled={isLoading}
          >
            Sign In
          </Button>
        </CSRFForm>

        <div className="text-center mt-6">
          <p className="text-gray-600">
            Don't have an account?{" "}
            <Link
              to="/register"
              className="text-lokasync-primary hover:text-lokasync-secondary"
            >
              Sign Up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
