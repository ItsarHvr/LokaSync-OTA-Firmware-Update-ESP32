import { useState, useEffect } from "react";
import Layout from "../../components/layout/Layout";
import Card from "../../components/ui/Card";
import Alert from "../../components/ui/Alert";
import { mqttController } from "../../controllers/MQTTController";
import type { MonitoringData } from "../../types";
import Chart from "chart.js/auto";

const Monitoring = () => {
  // State for monitoring data
  const [monitoringData, setMonitoringData] = useState<MonitoringData[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState("");
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [availableNodes, setAvailableNodes] = useState<
    { id: number; name: string }[]
  >([]);
  const [temperatureChart, setTemperatureChart] = useState<Chart<
    "line",
    number[],
    string
  > | null>(null);
  const [humidityChart, setHumidityChart] = useState<Chart<
    "line",
    number[],
    string
  > | null>(null);
  const [tdsChart, setTdsChart] = useState<Chart<
    "line",
    number[],
    string
  > | null>(null);

  // Connect to MQTT broker on component mount
  useEffect(() => {
    const connectToMQTT = async () => {
      try {
        setError("");
        // Connect to MQTT broker using environment variables
        await mqttController.connect();
        setIsConnected(true);

        // Subscribe to messages
        mqttController.onMessage((data) => {
          // Add timestamp if not present
          const dataWithTimestamp: MonitoringData = {
            ...data,
            timestamp: data.timestamp || new Date().toISOString(),
          };

          setMonitoringData((prev) => {
            // Keep only the latest 100 data points to avoid memory issues
            const newData = [dataWithTimestamp, ...prev].slice(0, 100);

            // Update available nodes
            const nodesSet = new Set(newData.map((d) => d.nodeName));
            const nodesArray = Array.from(nodesSet).map((name) => {
              const node = newData.find((d) => d.nodeName === name);
              return {
                id: node?.nodeId || 0,
                name,
              };
            });

            setAvailableNodes(nodesArray);

            // Auto-select the first node if none is selected
            if (!selectedNode && nodesArray.length > 0) {
              setSelectedNode(nodesArray[0].name);
            }

            return newData;
          });
        });
      } catch (err) {
        let errorMessage = "Failed to connect to MQTT broker";
        if (err instanceof Error) {
          errorMessage = err.message;
        }
        setError(errorMessage);
        setIsConnected(false);

        // Create dummy data for testing
        const generateDummyData = () => {
          const nodes = ["depok-node1-DHT11", "jakarta-node2-TDS"];
          const nodeId =
            nodes.indexOf(nodes[Math.floor(Math.random() * nodes.length)]) + 1;
          const nodeName = nodes[nodeId - 1];

          const now = new Date();
          const timestamp = now.toISOString();

          // Generate random data based on node type
          if (nodeName.includes("DHT11")) {
            return {
              nodeId,
              nodeName,
              temperature: 25 + Math.random() * 5,
              humidity: 60 + Math.random() * 20,
              timestamp,
            };
          } else {
            return {
              nodeId,
              nodeName,
              tds: 100 + Math.random() * 50,
              timestamp,
            };
          }
        };

        // Generate initial dummy data
        const initialData: MonitoringData[] = Array.from({ length: 20 }, () =>
          generateDummyData(),
        );
        setMonitoringData(initialData);

        // Set available nodes
        const nodesSet = new Set(initialData.map((d) => d.nodeName));
        const nodesArray = Array.from(nodesSet).map((name) => {
          const node = initialData.find((d) => d.nodeName === name);
          return {
            id: node?.nodeId || 0,
            name,
          };
        });

        setAvailableNodes(nodesArray);
        setSelectedNode(nodesArray[0]?.name || null);

        // Simulate receiving data every 3 seconds
        const interval = setInterval(() => {
          const newData = generateDummyData();
          setMonitoringData((prev) => [newData, ...prev].slice(0, 100));
        }, 3000);

        return () => clearInterval(interval);
      }
    };

    connectToMQTT();

    // Cleanup on component unmount
    return () => {
      if (isConnected) {
        mqttController.disconnect();
      }

      // Destroy charts
      if (temperatureChart) temperatureChart.destroy();
      if (humidityChart) humidityChart.destroy();
      if (tdsChart) tdsChart.destroy();
    };
  }, [isConnected, temperatureChart, humidityChart, tdsChart, selectedNode]);

  // Initialize and update charts when data or selected node changes
  useEffect(() => {
    // Helper to get data for the selected node
    const getNodeData = () => {
      if (!selectedNode) return [];
      return monitoringData
        .filter((data) => data.nodeName === selectedNode)
        .sort(
          (a, b) =>
            new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
        );
    };

    const nodeData = getNodeData();
    if (nodeData.length === 0) return;

    // Format timestamps for x-axis labels
    const formatTimestamp = (timestamp: string) => {
      const date = new Date(timestamp);
      return `${date.getHours()}:${date.getMinutes().toString().padStart(2, "0")}:${date.getSeconds().toString().padStart(2, "0")}`;
    };

    const timestamps = nodeData.map((data) => formatTimestamp(data.timestamp));

    // Check what type of data we have
    const hasDHTData =
      "temperature" in nodeData[0] && "humidity" in nodeData[0];
    const hasTDSData = "tds" in nodeData[0];
    // Temperature chart
    if (hasDHTData) {
      const temperatureData: number[] = nodeData.map((data) => {
        const typedData = data as MonitoringData & { temperature?: number };
        return typedData.temperature ?? 0; // Use 0 as fallback to ensure number type
      });
      const humidityData: number[] = nodeData.map((data) => {
        const typedData = data as MonitoringData & { humidity?: number };
        return typedData.humidity ?? 0; // Use 0 as fallback to ensure number type
      });

      // Temperature chart
      const temperatureCanvas = document.getElementById(
        "temperature-chart",
      ) as HTMLCanvasElement;
      if (temperatureCanvas) {
        // Destroy previous chart if it exists
        if (temperatureChart) temperatureChart.destroy();

        const newTempChart = new Chart(temperatureCanvas, {
          type: "line",
          data: {
            labels: timestamps,
            datasets: [
              {
                label: "Temperature (°C)",
                data: temperatureData,
                borderColor: "#ff6b6b",
                backgroundColor: "rgba(255, 107, 107, 0.1)",
                borderWidth: 2,
                tension: 0.4,
                fill: true,
              },
            ],
          },
          options: {
            responsive: true,
            plugins: {
              title: {
                display: true,
                text: "Temperature Over Time",
                font: {
                  size: 16,
                },
              },
              legend: {
                position: "top",
              },
            },
            scales: {
              y: {
                beginAtZero: false,
                title: {
                  display: true,
                  text: "Temperature (°C)",
                },
              },
              x: {
                title: {
                  display: true,
                  text: "Time",
                },
              },
            },
          },
        });

        setTemperatureChart(newTempChart);

        // Humidity chart
        const humidityCanvas = document.getElementById(
          "humidity-chart",
        ) as HTMLCanvasElement;
        if (humidityCanvas) {
          // Destroy previous chart if it exists
          if (humidityChart) humidityChart.destroy();

          const newHumidityChart = new Chart(humidityCanvas, {
            type: "line",
            data: {
              labels: timestamps,
              datasets: [
                {
                  label: "Humidity (%)",
                  data: humidityData,
                  borderColor: "#4dabf7",
                  backgroundColor: "rgba(77, 171, 247, 0.1)",
                  borderWidth: 2,
                  tension: 0.4,
                  fill: true,
                },
              ],
            },
            options: {
              responsive: true,
              plugins: {
                title: {
                  display: true,
                  text: "Humidity Over Time",
                  font: {
                    size: 16,
                  },
                },
                legend: {
                  position: "top",
                },
              },
              scales: {
                y: {
                  beginAtZero: false,
                  title: {
                    display: true,
                    text: "Humidity (%)",
                  },
                },
                x: {
                  title: {
                    display: true,
                    text: "Time",
                  },
                },
              },
            },
          });

          setHumidityChart(newHumidityChart);
        }
      }
    }
    // TDS chart
    if (hasTDSData) {
      const tdsData: number[] = nodeData.map((data) => {
        const typedData = data as MonitoringData & { tds?: number };
        return typedData.tds ?? 0; // Use 0 as fallback to ensure number type
      });

      const tdsCanvas = document.getElementById(
        "tds-chart",
      ) as HTMLCanvasElement;
      if (tdsCanvas) {
        // Destroy previous chart if it exists
        if (tdsChart) tdsChart.destroy();

        const newTDSChart = new Chart(tdsCanvas, {
          type: "line",
          data: {
            labels: timestamps,
            datasets: [
              {
                label: "TDS (ppm)",
                data: tdsData,
                borderColor: "#20c997",
                backgroundColor: "rgba(32, 201, 151, 0.1)",
                borderWidth: 2,
                tension: 0.4,
                fill: true,
              },
            ],
          },
          options: {
            responsive: true,
            plugins: {
              title: {
                display: true,
                text: "TDS Over Time",
                font: {
                  size: 16,
                },
              },
              legend: {
                position: "top",
              },
            },
            scales: {
              y: {
                beginAtZero: false,
                title: {
                  display: true,
                  text: "TDS (ppm)",
                },
              },
              x: {
                title: {
                  display: true,
                  text: "Time",
                },
              },
            },
          },
        });

        setTdsChart(newTDSChart);
      }
    }
  }, [monitoringData, selectedNode, humidityChart, tdsChart, temperatureChart]);

  // Get data for the selected node
  const getNodeData = () => {
    if (!selectedNode) return [];
    return monitoringData
      .filter((data) => data.nodeName === selectedNode)
      .sort(
        (a, b) =>
          new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
      );
  };

  // Determines which charts to show based on sensor type
  const renderCharts = () => {
    const nodeData = getNodeData();
    if (nodeData.length === 0)
      return (
        <p className="text-center text-gray-500">
          No data available for selected node
        </p>
      );

    const firstData = nodeData[0];
    const hasDHTData = "temperature" in firstData && "humidity" in firstData;
    const hasTDSData = "tds" in firstData;

    return (
      <div className="space-y-8">
        {hasDHTData && (
          <>
            <div className="lokasync-card">
              <canvas id="temperature-chart"></canvas>
            </div>
            <div className="lokasync-card">
              <canvas id="humidity-chart"></canvas>
            </div>
          </>
        )}

        {hasTDSData && (
          <div className="lokasync-card">
            <canvas id="tds-chart"></canvas>
          </div>
        )}
      </div>
    );
  };

  // Render the most recent readings in a card
  const renderLatestReadings = () => {
    const nodeData = getNodeData();
    if (nodeData.length === 0) return null;

    const latestData = nodeData[0];
    const timestamp = new Date(latestData.timestamp).toLocaleString();

    return (
      <Card className="mb-6">
        <h2 className="text-xl font-semibold text-lokasync-accent mb-4">
          Latest Readings
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {"temperature" in latestData && (
            <div className="bg-lokasync-light-green p-4 rounded-md text-center">
              <p className="text-gray-600 mb-1">Temperature</p>{" "}
              <p className="text-3xl font-bold text-lokasync-accent">
                {(
                  latestData as MonitoringData & { temperature: number }
                ).temperature.toFixed(1)}
                °C
              </p>
            </div>
          )}

          {"humidity" in latestData && (
            <div className="bg-lokasync-light-green p-4 rounded-md text-center">
              <p className="text-gray-600 mb-1">Humidity</p>{" "}
              <p className="text-3xl font-bold text-lokasync-accent">
                {(
                  latestData as MonitoringData & { humidity: number }
                ).humidity.toFixed(1)}
                %
              </p>
            </div>
          )}

          {"tds" in latestData && (
            <div className="bg-lokasync-light-green p-4 rounded-md text-center">
              <p className="text-gray-600 mb-1">TDS</p>{" "}
              <p className="text-3xl font-bold text-lokasync-accent">
                {(latestData as MonitoringData & { tds: number }).tds.toFixed(
                  1,
                )}{" "}
                ppm
              </p>
            </div>
          )}
        </div>
        <p className="text-sm text-gray-500 mt-4">Last updated: {timestamp}</p>
      </Card>
    );
  };

  return (
    <Layout title="Monitoring">
      <div className="mb-6 flex flex-col sm:flex-row sm:justify-between sm:items-center">
        <h1 className="text-3xl font-bold text-lokasync-accent mb-2 sm:mb-0">
          Real-time Monitoring
        </h1>

        {/* Node selector */}
        <div className="w-full sm:w-64">
          <select
            value={selectedNode || ""}
            onChange={(e) => setSelectedNode(e.target.value)}
            className="lokasync-input"
            disabled={availableNodes.length === 0}
          >
            <option value="" disabled>
              Select Node
            </option>
            {availableNodes.map((node) => (
              <option key={node.name} value={node.name}>
                {node.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <Alert type="error" message={error} onClose={() => setError("")} />
      )}

      {!isConnected && !error && (
        <Alert
          type="info"
          message="Using simulated data. MQTT connection unavailable."
          onClose={() => {}}
          className="text-center"
        />
      )}

      {/* Connection status */}
      <div className="mb-6 flex items-center justify-center">
        <span
          className={`inline-block w-3 h-3 rounded-full mr-2 ${
            isConnected ? "bg-green-500" : "bg-red-500"
          }`}
        ></span>
        <span
          className={`text-sm ${isConnected ? "text-gray-600" : "text-red-600 font-medium"}`}
        >
          {isConnected
            ? "Connected to MQTT broker"
            : "Not connected to MQTT broker"}
        </span>
      </div>

      {selectedNode ? (
        <>
          {/* Latest readings */}
          {renderLatestReadings()}

          {/* Charts */}
          {renderCharts()}
        </>
      ) : (
        <Card>
          <div className="text-center py-8">
            <p className="text-gray-500">
              {availableNodes.length === 0
                ? "Waiting for monitoring data..."
                : "Please select a node to view monitoring data"}
            </p>
          </div>
        </Card>
      )}
    </Layout>
  );
};

export default Monitoring;
