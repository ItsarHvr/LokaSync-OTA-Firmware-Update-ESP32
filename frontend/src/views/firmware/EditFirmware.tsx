import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Layout from "../../components/layout/Layout";
import Card from "../../components/ui/Card";
import Input from "../../components/ui/Input";
import Select from "../../components/ui/Select";
import Textarea from "../../components/ui/Textarea";
import Button from "../../components/ui/Button";
import Alert from "../../components/ui/Alert";
import CSRFForm from "../../components/ui/CSRFForm";
import { FirmwareController } from "../../controllers/FirmwareController";
import type { Firmware } from "../../types";

const EditFirmware = () => {
  const navigate = useNavigate();
  const { nodeName } = useParams<{ nodeName: string }>();

  // Form state
  const [formData, setFormData] = useState<Partial<Firmware>>({
    nodeId: undefined,
    nodeLocation: "",
    sensorType: "",
    firmwareDescription: "",
    firmwareVersion: "",
    firmwareUrl: "",
    nodeName: "",
  });

  // File state
  const [firmwareFile, setFirmwareFile] = useState<File | null>(null);

  // UI state
  const [isLoading, setIsLoading] = useState(false);
  const [isFetching, setIsFetching] = useState(true);
  const [error, setError] = useState("");

  // Sensor type options
  const sensorTypeOptions = [
    { value: "DHT11", label: "DHT11" },
    { value: "TDS", label: "TDS" },
    { value: "DS", label: "DS" },
  ];

  // Fetch firmware data
  useEffect(() => {
    const fetchFirmware = async () => {
      if (!nodeName) return;

      try {
        setIsFetching(true);
        setError(""); // This would be the actual API call in production
        // When implementing properly, use the actual API call
        // const firmware = await FirmwareController.getFirmwareByNodeId(nodeName);

        // For now, let's create dummy data
        const dummyFirmware: Firmware = {
          nodeName,
          nodeId: parseInt(nodeName.split("-")[1].replace("node", "")),
          nodeLocation: nodeName.includes("depok")
            ? "Depok Greenhouse"
            : "Jakarta Greenhouse",
          sensorType: nodeName.includes("DHT11")
            ? "DHT11"
            : nodeName.includes("TDS")
              ? "TDS"
              : "DS",
          firmwareDescription: `Description for ${nodeName}`,
          firmwareVersion: "1.0.0",
          firmwareUrl: `https://drive.google.com/example-${nodeName}.bin`,
        };

        setFormData(dummyFirmware);
      } catch (err: unknown) {
        if (err instanceof Error) {
          setError(err.message);
        } else {
          setError("Failed to fetch firmware data");
        }
      } finally {
        setIsFetching(false);
      }
    };

    fetchFirmware();
  }, [nodeName]);

  // Handle input changes
  const handleInputChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >,
  ) => {
    const { name, value } = e.target;

    // Convert nodeId to number if necessary
    if (name === "nodeId") {
      setFormData((prev) => ({
        ...prev,
        [name]: value ? parseInt(value) : undefined,
      }));
    } else {
      setFormData((prev) => ({ ...prev, [name]: value }));
    }
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

    if (!nodeName) {
      setError("Node name is missing");
      return;
    }

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

    // Validate firmware version format (e.g., 1.0.0)
    const versionRegex = /^\d+(\.\d+){0,2}$/;
    if (!versionRegex.test(formData.firmwareVersion)) {
      setError("Firmware version must be in a valid format (e.g., 1.0.0)");
      return;
    }

    // Either firmware URL or file must be provided or preserved from before
    if (!formData.firmwareUrl && !firmwareFile) {
      setError(
        "Please provide either a firmware URL or upload a firmware file",
      );
      return;
    }

    try {
      setIsLoading(true);
      setError("");

      // For now just simulate success (uncomment the actual call in production)
      await FirmwareController.updateFirmware(
        formData,
        firmwareFile || undefined,
      );
      console.log("Updating firmware:", formData, firmwareFile);

      // Navigate back to dashboard on success
      navigate("/dashboard", {
        state: { successMessage: "Firmware updated successfully!" },
      });
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to update firmware");
      }
    } finally {
      setIsLoading(false);
    }
  };

  if (isFetching) {
    return (
      <Layout title="Edit Firmware">
        <div className="flex justify-center items-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-lokasync-primary"></div>
          <span className="ml-3">Loading firmware data...</span>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Edit Firmware">
      <div className="mb-6 text-center">
        <h1 className="text-2xl font-bold text-lokasync-accent">
          Edit Firmware
        </h1>
        <p className="text-gray-600">Updating {nodeName}</p>
      </div>

      {error && (
        <Alert type="error" message={error} onClose={() => setError("")} />
      )}

      <div className="max-w-3xl mx-auto">
        <Card>
          <CSRFForm onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Node ID */}
              <Input
                label="Node ID"
                name="nodeId"
                type="number"
                value={formData.nodeId?.toString() || ""}
                onChange={handleInputChange}
                placeholder="Enter node ID"
                required
              />

              {/* Node Location */}
              <Input
                label="Node Location"
                name="nodeLocation"
                type="text"
                value={formData.nodeLocation || ""}
                onChange={handleInputChange}
                placeholder="Enter node location"
                required
              />

              {/* Sensor Type */}
              <Select
                label="Sensor Type"
                name="sensorType"
                value={formData.sensorType || ""}
                onChange={handleInputChange}
                options={sensorTypeOptions}
                required
              />

              {/* Firmware Version */}
              <Input
                label="Firmware Version"
                name="firmwareVersion"
                type="text"
                value={formData.firmwareVersion || ""}
                onChange={handleInputChange}
                placeholder="Enter firmware version (e.g., 1.0.0)"
                required
              />
            </div>

            {/* Firmware Description */}
            <Textarea
              label="Firmware Description (Optional)"
              name="firmwareDescription"
              value={formData.firmwareDescription || ""}
              onChange={handleInputChange}
              placeholder="Enter firmware description"
              rows={4}
            />

            {/* Firmware URL */}
            <Input
              label="Firmware URL (Optional if file is uploaded)"
              name="firmwareUrl"
              type="text"
              value={formData.firmwareUrl || ""}
              onChange={handleInputChange}
              placeholder="Enter firmware URL"
              helperText="Provide a direct download link to the firmware file"
            />

            {/* Firmware File */}
            <div className="mb-4">
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
                {formData.firmwareUrl
                  ? "Upload a new file to replace the current firmware"
                  : "Upload the firmware binary file"}
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
                Update Firmware
              </Button>
            </div>
          </CSRFForm>
        </Card>
      </div>
    </Layout>
  );
};

export default EditFirmware;
