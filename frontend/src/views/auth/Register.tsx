import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Input from "../../components/ui/Input";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import PasswordInput from "../../components/ui/PasswordInput";
import { useAuth } from "../../contexts";
import {
  isValidEmail,
  validatePassword,
  isValidFullName,
} from "../../utils/validation";

const Register = () => {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [fullNameError, setFullNameError] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [confirmPasswordError, setConfirmPasswordError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const { register } = useAuth();

  // Set document title
  useEffect(() => {
    document.title = "LokaSync | Register";
  }, []);

  const validateForm = (): boolean => {
    let isValid = true;

    // Reset errors
    setFullNameError("");
    setEmailError("");
    setPasswordError("");
    setConfirmPasswordError("");

    // Validate full name
    if (!fullName) {
      setFullNameError("Full name is required");
      isValid = false;
    } else if (!isValidFullName(fullName)) {
      setFullNameError("Full name can only contain letters and spaces");
      isValid = false;
    }

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
    } else {
      const passwordValidation = validatePassword(password);
      if (!passwordValidation.isValid) {
        setPasswordError(passwordValidation.message);
        isValid = false;
      }
    }

    // Validate password confirmation
    if (!confirmPassword) {
      setConfirmPasswordError("Please confirm your password");
      isValid = false;
    } else if (password !== confirmPassword) {
      setConfirmPasswordError("Passwords do not match");
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
      await register(email, password, fullName);

      // Clear form
      setFullName("");
      setEmail("");
      setPassword("");
      setConfirmPassword("");

      // Set success message
      setSuccessMessage(
        "Email confirmation link has been sent. Please verify your email to complete registration.",
      );
      setConfirmPassword("");
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to create an account");
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
            Create a new account
          </h1>
          <p className="text-gray-600 mt-2">Join to LokaSync Platform</p>
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
            label="Full Name"
            type="text"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="Enter your full name"
            error={fullNameError}
            required
            autoFocus
          />

          <Input
            label="Email Address"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter your email"
            error={emailError}
            required
          />

          <PasswordInput
            label="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            error={passwordError}
            helperText="Password must be at least 8 characters with letters, numbers, and symbols"
            required
          />

          <PasswordInput
            label="Confirm Password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="Confirm your password"
            error={confirmPasswordError}
            required
          />

          <Button
            type="submit"
            fullWidth
            size="lg"
            isLoading={isLoading}
            disabled={isLoading}
          >
            Sign Up
          </Button>
        </CSRFForm>

        <div className="text-center mt-6">
          <p className="text-gray-600">
            Already have an account?{" "}
            <Link
              to="/login"
              className="text-lokasync-primary hover:text-lokasync-secondary"
            >
              Sign In
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Register;
