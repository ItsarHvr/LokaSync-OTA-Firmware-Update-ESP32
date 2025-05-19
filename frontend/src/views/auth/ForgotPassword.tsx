import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Input from "../../components/ui/Input";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import { useAuth } from "../../contexts";
import { isValidEmail } from "../../utils/validation";

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [emailError, setEmailError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const { resetPassword } = useAuth();

  // Set document title
  useEffect(() => {
    document.title = "LokaSync | Forgot Password";
  }, []);

  const validateForm = (): boolean => {
    let isValid = true;

    // Reset errors
    setEmailError("");

    // Validate email
    if (!email) {
      setEmailError("Email is required");
      isValid = false;
    } else if (!isValidEmail(email)) {
      setEmailError("Please enter a valid email address");
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
      await resetPassword(email);
      setSuccessMessage(
        "Password reset email sent! Check your inbox for further instructions.",
      );
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to reset password");
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
            Reset Password
          </h1>
          <p className="text-gray-600 mt-2">
            We'll send you a link to reset your password
          </p>
        </div>
        {error && (
          <Alert type="error" message={error} onClose={() => setError("")} />
        )}
        {successMessage && (
          <Alert
            type="success"
            message={successMessage}
            onClose={() => setSuccessMessage("")}
          />
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

          <Button
            type="submit"
            fullWidth
            size="lg"
            isLoading={isLoading}
            disabled={isLoading}
          >
            Send Reset Link
          </Button>
        </CSRFForm>
        <div className="text-center mt-6">
          <p className="text-gray-600">
            Remember your password?{" "}
            <Link
              to="/login"
              className="text-lokasync-primary hover:text-lokasync-secondary"
            >
              Back to Login
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
