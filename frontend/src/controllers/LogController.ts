import { fetchWithAuth, createQueryParams } from "../utils/api";
import type { LogResponse, Log } from "../types";

// LogController for handling log-related API calls
export const LogController = {
  // Get all logs with optional filters
  async getAllLogs(
    page = 1,
    size = 10,
    filters: {
      nodeId?: number;
      nodeLocation?: string;
      sensorType?: string;
      status?: string;
    } = {},
  ): Promise<LogResponse> {
    const queryParams = createQueryParams({
      page,
      size,
      ...filters,
    });

    return fetchWithAuth<LogResponse>(`/log${queryParams}`);
  },
  
  // Get logs for a specific node
  async getLogsByNodeName(nodeName: string): Promise<Log[]> {
    const queryParams = createQueryParams({
      nodeName
    });
    
    try {
      const response = await fetchWithAuth<LogResponse>(`/log${queryParams}`);
      return response.logData;
    } catch (error) {
      console.error(`Error fetching logs for ${nodeName}:`, error);
      return [];
    }
  }
};
