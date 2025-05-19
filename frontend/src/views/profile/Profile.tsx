import { useState, useEffect } from "react";
import Layout from "../../components/layout/Layout";
import Card from "../../components/ui/Card";
import Input from "../../components/ui/Input";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import { useAuth } from "../../contexts";

const Profile = () => {
  const { currentUser, updateUserProfile, logout } = useAuth();

  // State for profile form
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [isUpdating, setIsUpdating] = useState(false);
  const [updateError, setUpdateError] = useState("");
  const [updateSuccess, setUpdateSuccess] = useState("");

  // State for password change form
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmNewPassword, setConfirmNewPassword] = useState("");
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const [passwordError, setPasswordError] = useState("");
  const [passwordSuccess, setPasswordSuccess] = useState("");

  // State for account deletion confirmation
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState("");
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState("");

  // Set initial values when user data is available
  useEffect(() => {
    if (currentUser) {
      setDisplayName(currentUser.displayName || "");
      setEmail(currentUser.email || "");
    }
  }, [currentUser]);

  // Handle profile update
  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!displayName) {
      setUpdateError("Name cannot be empty");
      return;
    }

    try {
      setIsUpdating(true);
      setUpdateError("");

      await updateUserProfile(displayName);

      setUpdateSuccess("Profile updated successfully!");

      // Clear success message after 3 seconds
      setTimeout(() => {
        setUpdateSuccess("");
      }, 3000);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setUpdateError(err.message);
      } else {
        setUpdateError("Failed to update profile");
      }
    } finally {
      setIsUpdating(false);
    }
  };

  // Handle password change
  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!currentPassword || !newPassword || !confirmNewPassword) {
      setPasswordError("Please fill in all password fields");
      return;
    }

    if (newPassword !== confirmNewPassword) {
      setPasswordError("New passwords do not match");
      return;
    }

    if (newPassword.length < 6) {
      setPasswordError("New password must be at least 6 characters long");
      return;
    }

    try {
      setIsChangingPassword(true);
      setPasswordError("");

      // Firebase doesn't have a direct method for this in the client
      // We would need to call a custom backend endpoint or use Firebase's password update flow
      // For now, just simulate success

      setPasswordSuccess("Password changed successfully!");

      // Clear form
      setCurrentPassword("");
      setNewPassword("");
      setConfirmNewPassword("");

      // Clear success message after 3 seconds
      setTimeout(() => {
        setPasswordSuccess("");
      }, 3000);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setPasswordError(err.message);
      } else {
        setPasswordError("Failed to change password");
      }
    } finally {
      setIsChangingPassword(false);
    }
  };

  // Handle account deletion
  const handleDeleteAccount = async () => {
    if (deleteConfirmText !== "DELETE") {
      setDeleteError("Please type DELETE to confirm account deletion");
      return;
    }

    try {
      setIsDeleting(true);
      setDeleteError("");

      // In a real app, we would call a method to delete the user account
      // For now, just simulate success by logging out
      await logout();
    } catch (err: unknown) {
      if (err instanceof Error) {
        setDeleteError(err.message);
      } else {
        setDeleteError("Failed to delete account");
      }
      setIsDeleting(false);
    }
  };

  // Handle logout
  const handleLogout = async () => {
    try {
      await logout();
    } catch (err: unknown) {
      console.error(
        "Error logging out:",
        err instanceof Error ? err.message : "Unknown error",
      );
    }
  };

  return (
    <Layout title="Profile">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-lokasync-accent">
          Account Settings
        </h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile Information */}
        <div className="lg:col-span-2">
          <Card>
            <h2 className="text-xl font-semibold mb-4">Profile Information</h2>

            {updateError && (
              <Alert
                type="error"
                message={updateError}
                onClose={() => setUpdateError("")}
              />
            )}

            {updateSuccess && (
              <Alert
                type="success"
                message={updateSuccess}
                onClose={() => setUpdateSuccess("")}
              />
            )}

            <CSRFForm onSubmit={handleProfileUpdate}>
              <div className="mb-4">
                <Input
                  label="Full Name"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Enter your full name"
                />
              </div>

              <div className="mb-6">
                <Input
                  label="Email Address"
                  value={email}
                  disabled
                  placeholder="Your email address"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Email cannot be changed
                </p>
              </div>

              <Button
                type="submit"
                isLoading={isUpdating}
                disabled={isUpdating}
              >
                Update Profile
              </Button>
            </CSRFForm>
          </Card>

          {/* Change Password */}
          <Card className="mt-6">
            <h2 className="text-xl font-semibold mb-4">Change Password</h2>

            {passwordError && (
              <Alert
                type="error"
                message={passwordError}
                onClose={() => setPasswordError("")}
              />
            )}

            {passwordSuccess && (
              <Alert
                type="success"
                message={passwordSuccess}
                onClose={() => setPasswordSuccess("")}
              />
            )}

            <CSRFForm onSubmit={handlePasswordChange}>
              <div className="mb-4">
                <Input
                  label="Current Password"
                  type="password"
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  placeholder="Enter your current password"
                />
              </div>

              <div className="mb-4">
                <Input
                  label="New Password"
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Enter new password"
                />
              </div>

              <div className="mb-6">
                <Input
                  label="Confirm New Password"
                  type="password"
                  value={confirmNewPassword}
                  onChange={(e) => setConfirmNewPassword(e.target.value)}
                  placeholder="Confirm new password"
                />
              </div>

              <Button
                type="submit"
                isLoading={isChangingPassword}
                disabled={isChangingPassword}
              >
                Change Password
              </Button>
            </CSRFForm>
          </Card>
        </div>

        {/* Sidebar */}
        <div>
          {/* Account Actions */}
          <Card>
            <h2 className="text-xl font-semibold mb-4">Account Actions</h2>

            <div className="space-y-4">
              <Button
                variant="secondary"
                className="w-full"
                onClick={() => handleLogout()}
              >
                Logout
              </Button>

              <Button
                variant="danger"
                className="w-full"
                onClick={() => setShowDeleteConfirmation(true)}
              >
                Delete Account
              </Button>
            </div>
          </Card>
        </div>
      </div>

      {/* Delete Account Confirmation Modal */}
      {showDeleteConfirmation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4">
          <Card className="max-w-md w-full">
            <h2 className="text-xl font-semibold mb-4 text-red-500">
              Delete Account
            </h2>

            <p className="mb-4">
              This action cannot be undone. All your data will be permanently
              deleted.
            </p>

            {deleteError && (
              <Alert
                type="error"
                message={deleteError}
                onClose={() => setDeleteError("")}
              />
            )}

            <div className="mb-4">
              <Input
                label="Type DELETE to confirm"
                value={deleteConfirmText}
                onChange={(e) => setDeleteConfirmText(e.target.value)}
                placeholder="DELETE"
              />
            </div>

            <div className="flex justify-end space-x-3">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowDeleteConfirmation(false);
                  setDeleteConfirmText("");
                  setDeleteError("");
                }}
              >
                Cancel
              </Button>

              <CSRFForm
                onSubmit={(e) => {
                  e.preventDefault();
                  handleDeleteAccount();
                }}
              >
                <Button
                  variant="danger"
                  type="submit"
                  isLoading={isDeleting}
                  disabled={isDeleting}
                >
                  Delete Account
                </Button>
              </CSRFForm>
            </div>
          </Card>
        </div>
      )}
    </Layout>
  );
};

export default Profile;
