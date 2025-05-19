import { useState } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/layout/Layout";
import Card from "../../components/ui/Card";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Textarea from "../../components/ui/Textarea";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import { FirmwareController } from "../../controllers/FirmwareController";

const AddFirmware = () => {
  const navigate = useNavigate();

  // Form state
  const [formData, setFormData] = useState({
    nodeId: "",
    nodeLocation: "",
    sensorType: "DHT11", // Default sensor type
    firmwareDescription: "",
    firmwareVersion: "",
    firmwareUrl: "",
  });

  // File state
  const [firmwareFile, setFirmwareFile] = useState<File | null>(null);

  // UI state
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  // Sensor type options
  const sensorTypeOptions = [
    { value: "DHT11", label: "DHT11" },
    { value: "TDS", label: "TDS" },
    { value: "DS", label: "DS" },
  ];

  // Handle input changes
  const handleInputChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >,
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  // Handle file change
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];

      // Check if file is a .bin file
      if (!file.name.endsWith(".bin")) {
        setError("Only .bin files are allowed");
        setFirmwareFile(null);
        return;
      }

      setFirmwareFile(file);
      setError("");
    }
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    if (
      !formData.nodeId ||
      !formData.nodeLocation ||
      !formData.sensorType ||
      !formData.firmwareVersion
    ) {
      setError("Please fill in all required fields");
      return;
    }

    // Validate node ID is a number
    if (isNaN(Number(formData.nodeId))) {
      setError("Node ID must be a number");
      return;
    }

    // Validate firmware version format (e.g., 1.0.0)
    const versionRegex = /^\d+(\.\d+){0,2}$/;
    if (!versionRegex.test(formData.firmwareVersion)) {
      setError("Firmware version must be in a valid format (e.g., 1.0.0)");
      return;
    }

    // Either firmware URL or file must be provided
    if (!formData.firmwareUrl && !firmwareFile) {
      setError(
        "Please provide either a firmware URL or upload a firmware file",
      );
      return;
    }

    try {
      setIsLoading(true);
      setError("");

      // Prepare firmware data
      const firmwareData = {
        nodeId: parseInt(formData.nodeId),
        nodeLocation: formData.nodeLocation,
        sensorType: formData.sensorType,
        firmwareDescription: formData.firmwareDescription,
        firmwareVersion: formData.firmwareVersion,
        firmwareUrl: formData.firmwareUrl,
      };
      // For now just simulate success (uncomment the actual call in production)
      await FirmwareController.addFirmware(
        firmwareData,
        firmwareFile || undefined,
      );
      console.log("Adding firmware:", firmwareData, firmwareFile);

      // Navigate back to dashboard on success
      navigate("/dashboard", {
        state: { successMessage: "Firmware added successfully!" },
      });
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to add firmware");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Layout title="Add Firmware">
      <div className="mb-6 text-center">
        <h1 className="text-3xl font-bold text-lokasync-accent">
          Add New Firmware
        </h1>
        <p className="text-gray-600 mt-1">
          Add a new firmware to your IoT devices
        </p>
      </div>

      {error && (
        <Alert type="error" message={error} onClose={() => setError("")} />
      )}

      <div className="max-w-4xl mx-auto">
        <Card>
          <CSRFForm onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Node ID */}
              <Input
                label="Node ID"
                name="nodeId"
                type="number"
                value={formData.nodeId}
                onChange={handleInputChange}
                placeholder="Enter node ID"
                required
              />

              {/* Node Location */}
              <Input
                label="Node Location"
                name="nodeLocation"
                type="text"
                value={formData.nodeLocation}
                onChange={handleInputChange}
                placeholder="Enter node location"
                required
              />

              {/* Sensor Type */}
              <Select
                label="Sensor Type"
                name="sensorType"
                value={formData.sensorType}
                onChange={handleInputChange}
                options={sensorTypeOptions}
                required
              />

              {/* Firmware Version */}
              <Input
                label="Firmware Version"
                name="firmwareVersion"
                type="text"
                value={formData.firmwareVersion}
                onChange={handleInputChange}
                placeholder="Enter firmware version (e.g., 1.0.0)"
                required
              />
            </div>

            {/* Firmware Description */}
            <Textarea
              label="Firmware Description (Optional)"
              name="firmwareDescription"
              value={formData.firmwareDescription}
              onChange={handleInputChange}
              placeholder="Enter firmware description"
              rows={4}
            />

            {/* Firmware URL */}
            <Input
              label="Firmware URL (Optional if file is uploaded)"
              name="firmwareUrl"
              type="text"
              value={formData.firmwareUrl}
              onChange={handleInputChange}
              placeholder="Enter firmware URL"
              helperText="Provide a direct download link to the firmware file"
            />

            {/* Firmware File */}
            <div className="mb-6">
              <label className="block text-gray-700 mb-1">
                Firmware File (.bin only){" "}
                {!formData.firmwareUrl && (
                  <span className="text-red-500">*</span>
                )}
              </label>
              <input
                type="file"
                accept=".bin"
                onChange={handleFileChange}
                className="block w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:border-lokasync-primary"
                required={!formData.firmwareUrl}
              />
              <p className="mt-1 text-sm text-gray-500">
                Upload the firmware binary file
              </p>
            </div>

            <div className="flex justify-end space-x-4 mt-6">
              <Button
                type="button"
                variant="outline"
                onClick={() => navigate("/dashboard")}
              >
                Cancel
              </Button>
              <Button type="submit" isLoading={isLoading} disabled={isLoading}>
                Add Firmware
              </Button>
            </div>
          </CSRFForm>
        </Card>
      </div>
    </Layout>
  );
};

export default AddFirmware;
