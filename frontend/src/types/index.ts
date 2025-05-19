// Types for the LokaSync application

// Auth types
export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
}

// Firmware types
export interface Firmware {
  firmwareDescription: string;
  firmwareVersion: string;
  firmwareUrl: string;
  nodeId: number;
  nodeLocation: string;
  nodeName: string;
  sensorType: string;
}

export interface FirmwarePayload extends Firmware {
  _token: string;
}

export interface FirmwareResponse {
  message: string;
  statusCode: number;
  page: number;
  size: number;
  totalData: number;
  totalPage: number;
  filterOptions: {
    nodeId: number[];
    nodeLocation: string[];
    sensorType: string[];
  };
  firmwareData: Firmware[];
}

// Log types
export interface Log extends Firmware {
  updatedAt: string;
  status: string;
}

export interface LogResponse {
  message: string;
  statusCode: number;
  page: number;
  size: number;
  totalData: number;
  totalPage: number;
  filterOptions: {
    nodeId: number[];
    nodeLocation: string[];
    sensorType: string[];
    status: string[];
  };
  logData: Log[];
}

// Monitoring types
export interface MonitoringData {
  nodeId: number;
  nodeName: string;
  temperature?: number;
  humidity?: number;
  tds?: number;
  timestamp: string;
}

// Type guards for MonitoringData
export function hasTemperatureAndHumidity(data: MonitoringData): boolean {
  return data.temperature !== undefined && data.humidity !== undefined;
}

export function hasTDS(data: MonitoringData): boolean {
  return data.tds !== undefined;
}
