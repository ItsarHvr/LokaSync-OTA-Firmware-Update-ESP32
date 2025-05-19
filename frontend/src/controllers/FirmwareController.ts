// filepath: d:\Kuliah\Semester6\09_Proyek-Kekhususan\lokasync-web\frontend\src\controllers\FirmwareController.ts.new
import { fetchWithAuth, createQueryParams } from "../utils/api";
import type { Firmware, FirmwareResponse, FirmwarePayload } from "../types";
import { auth } from "../firebase";
import { mqttController } from "./MQTTController";

// Define return types for API endpoints
type ApiResponse = {
  message: string;
  statusCode: number;
};

// FirmwareController for handling firmware-related API calls
export const FirmwareController = {
  // Get all firmware with optional filters
  async getAllFirmware(
    page = 1,
    size = 10,
    filters: {
      nodeId?: number;
      nodeLocation?: string;
      sensorType?: string;
    } = {},
  ): Promise<FirmwareResponse> {
    try {
      const queryParams = createQueryParams({
        page,
        size,
        ...filters,
      });

      return await fetchWithAuth<FirmwareResponse>(`/firmware${queryParams}`);
    } catch (err) {
      // If the API call fails, we can return dummy data during development
      console.warn(`Error fetching firmware data: ${err}`);

      // Create dummy data for testing
      const dummyData: Firmware[] = Array.from({ length: 10 }, (_, i) => ({
        firmwareDescription: `Firmware description ${i + 1}`,
        firmwareVersion: `1.0.${i}`,
        firmwareUrl: `https://drive.google.com/example-${i}.bin`,
        nodeId: (i % 5) + 1,
        nodeLocation: i % 2 === 0 ? "Depok Greenhouse" : "Jakarta Greenhouse",
        nodeName: `${i % 2 === 0 ? "depok" : "jakarta"}-node${(i % 5) + 1}-${i % 3 === 0 ? "DHT11" : i % 3 === 1 ? "TDS" : "DS"}`,
        sensorType: i % 3 === 0 ? "DHT11" : i % 3 === 1 ? "TDS" : "DS",
      }));

      const dummyResponse: FirmwareResponse = {
        message: "Success",
        statusCode: 200,
        page,
        size,
        totalData: 20,
        totalPage: 2,
        filterOptions: {
          nodeId: [1, 2, 3, 4, 5],
          nodeLocation: ["Depok Greenhouse", "Jakarta Greenhouse"],
          sensorType: ["DHT11", "TDS", "DS"],
        },
        firmwareData: dummyData,
      };

      return dummyResponse;
    }
  },

  // Add new firmware
  async addFirmware(
    firmware: Omit<Firmware, "nodeName">,
    file?: File,
  ): Promise<ApiResponse> {
    if (file) {
      // If file is provided, use FormData
      const formData = new FormData();
      formData.append("file", file);
      Object.entries(firmware).forEach(([key, value]) => {
        formData.append(key, String(value));
      });

      return fetchWithAuth<ApiResponse>("/firmware", {
        method: "POST",
        body: formData,
        // Don't set Content-Type header for FormData, but keep the CSRF token header
      });
    } else {
      // If no file, use JSON
      return fetchWithAuth<ApiResponse>("/firmware", {
        method: "POST",
        body: JSON.stringify(firmware),
      });
    }
  },

  // Update firmware
  async updateFirmware(
    nodeName: string,
    firmware: Partial<Firmware>,
    file?: File,
  ): Promise<ApiResponse> {
    if (file) {
      // If file is provided, use FormData
      const formData = new FormData();
      formData.append("file", file);
      Object.entries(firmware).forEach(([key, value]) => {
        if (value !== undefined) {
          formData.append(key, String(value));
        }
      });

      return fetchWithAuth<ApiResponse>(`/firmware/${nodeName}`, {
        method: "PUT",
        body: formData,
        // Don't set Content-Type header for FormData, but keep the CSRF token header
      });
    } else {
      // If no file, use JSON
      return fetchWithAuth<ApiResponse>(`/firmware/${nodeName}`, {
        method: "PUT",
        body: JSON.stringify(firmware),
      });
    }
  },

  // Delete firmware
  async deleteFirmware(nodeName: string): Promise<ApiResponse> {
    return fetchWithAuth<ApiResponse>(`/firmware/${nodeName}`, {
      method: "DELETE",
    });
  },

  // Get firmware by nodeName
  async getFirmwareByNodeName(nodeName: string): Promise<Firmware> {
    return fetchWithAuth<Firmware>(`/firmware/${nodeName}`);
  }, // Generate JWT token for MQTT payload
  async generateMQTTToken(): Promise<string> {
    // This would call your backend to generate a token
    const token = await auth.currentUser?.getIdToken();
    return token || "";
  },
  // Publish firmware update via MQTT
  async publishFirmwareUpdate(firmware: Firmware): Promise<ApiResponse> {
    try {
      const token = await this.generateMQTTToken();

      const payload: FirmwarePayload = {
        ...firmware,
        _token: token,
      };

      // First, try the API endpoint
      const result = await fetchWithAuth<ApiResponse>("/firmware/publish", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      // If we have a real MQTT connection, also publish directly
      // This can be removed in production if the API handles MQTT
      mqttController.publishUpdate(
        firmware.nodeId,
        firmware.firmwareUrl,
        firmware.firmwareVersion,
      );

      return result;
    } catch (error) {
      console.error("Error publishing firmware update:", error);
      throw error;
    }
  },
};
