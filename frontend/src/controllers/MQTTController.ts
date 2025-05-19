import mqtt from "mqtt";
import type { MonitoringData } from "../types";

// Get MQTT config from environment variables
const MQTT_CONFIG = {
  brokerUrl: import.meta.env.VITE_MQTT_BROKER_URL || "ws://localhost:9001",
  username: import.meta.env.VITE_MQTT_USERNAME,
  password: import.meta.env.VITE_MQTT_PASSWORD,
  baseTopic: "/LokaSync/CloudOTA",
};

// MQTTController for handling MQTT connections and messaging
export class MQTTController {
  private client: mqtt.MqttClient | null = null;
  private isConnected = false;
  private monitoringTopic = `${MQTT_CONFIG.baseTopic}/Monitoring`;
  private updateTopic = `${MQTT_CONFIG.baseTopic}/Update`;
  private callbacks: Array<(data: MonitoringData) => void> = [];

  // Connect to MQTT broker
  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      // Connect with credentials if available
      const options: mqtt.IClientOptions = {
        username: MQTT_CONFIG.username,
        password: MQTT_CONFIG.password,
        reconnectPeriod: 5000, // Reconnect every 5 seconds
        connectTimeout: 30000, // Timeout after 30 seconds
      };

      this.client = mqtt.connect(MQTT_CONFIG.brokerUrl, options);

      this.client.on("connect", () => {
        console.log("Connected to MQTT broker");
        this.isConnected = true;
        this.subscribe();
        resolve();
      });

      this.client.on("error", (error) => {
        console.error("MQTT connection error:", error);
        reject(error);
      });

      this.client.on("message", (_topic, message) => {
        try {
          const data = JSON.parse(message.toString()) as MonitoringData;
          this.callbacks.forEach((callback) => callback(data));
        } catch (error) {
          console.error("Error parsing MQTT message:", error);
        }
      });
    });
  }

  // Subscribe to the monitoring topic
  private subscribe(): void {
    if (this.isConnected && this.client) {
      this.client.subscribe(this.monitoringTopic, (err) => {
        if (err) {
          console.error("Error subscribing to topic:", err);
        } else {
          console.log(`Subscribed to ${this.monitoringTopic}`);
        }
      });
    }
  }

  // Add a callback to be called when a message is received
  onMessage(callback: (data: MonitoringData) => void): void {
    this.callbacks.push(callback);
  }

  // Publish a message to a specific topic
  publish(topic: string, message: Record<string, unknown>): void {
    if (this.isConnected && this.client) {
      this.client.publish(topic, JSON.stringify(message));
    }
  }

  // Publish firmware update
  publishUpdate(nodeId: number, firmwareUrl: string, version: string): void {
    if (this.isConnected && this.client) {
      const updateMessage = {
        nodeId,
        firmwareUrl,
        version,
        timestamp: new Date().toISOString(),
      };
      this.publish(`${this.updateTopic}/${nodeId}`, updateMessage);
    }
  }

  // Disconnect from the MQTT broker
  disconnect(): void {
    if (this.client) {
      this.client.end();
      this.isConnected = false;
      this.callbacks = [];
    }
  }
}

// Create a singleton instance
export const mqttController = new MQTTController();
