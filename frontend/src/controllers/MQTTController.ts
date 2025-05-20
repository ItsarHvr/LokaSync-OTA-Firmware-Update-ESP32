import mqtt from "mqtt";
import type { MonitoringData } from "../types";

// Get MQTT config from environment variables with proper protocol handling
const MQTT_CONFIG = {
  // In browser environments, we need to use WebSockets
  brokerUrl: `ws://${import.meta.env.VITE_MQTT_BROKER_URL || "broker.emqx.io"}:8083/mqtt`,
  // Regular MQTT port is 1883, but WebSocket is typically on 8083 or 8084 for SSL
  brokerPort: import.meta.env.VITE_MQTT_BROKER_PORT || 8083,
  username: import.meta.env.VITE_MQTT_USERNAME || undefined,
  password: import.meta.env.VITE_MQTT_PASSWORD || undefined,
  baseTopic: "LokaSync/CloudOTA",
};

// MQTTController for handling MQTT connections and messaging
export class MQTTController {
  private client: mqtt.MqttClient | null = null;
  private isConnected = false;
  private monitoringTopic = `${MQTT_CONFIG.baseTopic}/Monitoring`;
  private firmwareTopic = `${MQTT_CONFIG.baseTopic}/Firmware`;
  // private logTopic = `${MQTT_CONFIG.baseTopic}/Log`;
  private callbacks: Array<(data: MonitoringData) => void> = [];
  private connectPromise: Promise<void> | null = null;

  // Connect to MQTT broker
  connect(): Promise<void> {
    // Return existing promise if a connection is already being attempted
    if (this.connectPromise) {
      return this.connectPromise;
    }

    this.connectPromise = new Promise((resolve, reject) => {
      if (this.isConnected && this.client) {
        resolve(); // Already connected
        this.connectPromise = null;
        return;
      }

      // Connect with credentials if available
      const options: mqtt.IClientOptions = {
        clientId: `lokasync_frontend_${Math.random().toString(16).substring(2, 10)}`,
        username: MQTT_CONFIG.username || undefined,
        password: MQTT_CONFIG.password || undefined,
        reconnectPeriod: 5000, // Reconnect every 5 seconds
        connectTimeout: 30000, // Timeout after 30 seconds
        keepalive: 60,
      };

      console.log(`Connecting to MQTT broker at ${MQTT_CONFIG.brokerUrl} with options:`, 
        { ...options, password: options.password ? '****' : undefined });
      
      try {
        // Connect to the broker using the WebSocket URL
        this.client = mqtt.connect(MQTT_CONFIG.brokerUrl, options);

        this.client.on("connect", () => {
          console.log("Connected to MQTT broker successfully");
          this.isConnected = true;
          this.subscribe();
          resolve();
          this.connectPromise = null;
        });

        this.client.on("error", (error) => {
          console.error("MQTT connection error:", error);
          reject(error);
          this.connectPromise = null;
        });

        this.client.on("close", () => {
          console.log("MQTT connection closed");
          this.isConnected = false;
        });

        this.client.on("message", (_topic, message) => {
          try {
            console.log(`Received message on ${_topic}:`, message.toString());
            const data = JSON.parse(message.toString()) as MonitoringData;
            this.callbacks.forEach((callback) => callback(data));
          } catch (error) {
            console.error("Error parsing MQTT message:", error);
          }
        });
      } catch (err) {
        console.error("Error creating MQTT client:", err);
        reject(err);
        this.connectPromise = null;
      }
    });

    return this.connectPromise;
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
    const messageStr = JSON.stringify(message);
    
    if (!this.client || !this.isConnected) {
      console.warn("Cannot publish: MQTT client not connected. Attempting to connect...");
      
      this.connect()
        .then(() => {
          console.log(`Connected now, publishing to ${topic}`);
          if (this.client) {
            console.log(`Publishing message: ${messageStr}`);
            this.client.publish(topic, messageStr, { qos: 1 }, (err) => {
              if (err) {
                console.error(`Error publishing message to ${topic}:`, err);
              } else {
                console.log(`Successfully published message to ${topic}`);
              }
            });
          }
        })
        .catch(err => {
          console.error("Failed to connect for publishing:", err);
        });
      return;
    }

    console.log(`Publishing to ${topic}: ${messageStr}`);
    this.client.publish(topic, messageStr, { qos: 1 }, (err) => {
      if (err) {
        console.error(`Error publishing message to ${topic}:`, err);
      } else {
        console.log(`Successfully published message to ${topic}`);
      }
    });
  }

  // Publish firmware update
  publishUpdate(nodeId: number, firmwareUrl: string, version: string): void {
    const updateMessage = {
      node_id: nodeId,
      firmware_url: firmwareUrl,
      firmware_version: version,
      timestamp: new Date().toISOString(),
    };
    
    this.publish(`${this.firmwareTopic}/${nodeId}`, updateMessage);
  }

  // Disconnect from the MQTT broker
  disconnect(): void {
    if (this.client) {
      this.client.end(true, () => {
        console.log("MQTT client disconnected");
      });
      this.isConnected = false;
      this.callbacks = [];
    }
  }
  
  // Check if connected
  getConnectionStatus(): boolean {
    return this.isConnected;
  }
}

// Create a singleton instance
export const mqttController = new MQTTController();