import { useState, useEffect } from "react";
import Layout from "../../components/layout/Layout";
import Card from "../../components/ui/Card";
import Select from "../../components/ui/Select";
import Pagination from "../../components/ui/Pagination";
import Alert from "../../components/ui/Alert";
import { LogController } from "../../controllers/LogController";
import type { Log } from "../../types";

const LogPage = () => {
  // State for log data
  const [logs, setLogs] = useState<Log[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");
  // State for pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [pageSize] = useState(10);
  const [totalData, setTotalData] = useState(0);

  // State for filters
  const [filterOptions, setFilterOptions] = useState<{
    nodeId: number[];
    nodeLocation: string[];
    sensorType: string[];
    status: string[];
  }>({
    nodeId: [],
    nodeLocation: [],
    sensorType: [],
    status: [],
  });

  // Active filters
  const [selectedNodeId, setSelectedNodeId] = useState<number | undefined>(
    undefined,
  );
  const [selectedLocation, setSelectedLocation] = useState<string | undefined>(
    undefined,
  );
  const [selectedSensorType, setSelectedSensorType] = useState<
    string | undefined
  >(undefined);
  const [selectedStatus, setSelectedStatus] = useState<string | undefined>(
    undefined,
  );

  // Fetch log data when filters or pagination changes
  const fetchLogs = async () => {
    try {
      setIsLoading(true);
      setError("");

      const response = await LogController.getAllLogs(currentPage, pageSize, {
        nodeId: selectedNodeId,
        nodeLocation: selectedLocation,
        sensorType: selectedSensorType,
        status: selectedStatus,
      });

      setLogs(response.logData);
      setTotalPages(response.totalPage);
      setTotalData(response.totalData);
      setFilterOptions(response.filterOptions);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to fetch log data");
      }

      // Create dummy data for testing (remove in production)
      const dummyData: Log[] = Array.from({ length: 10 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - i);

        return {
          firmwareDescription: `Firmware description ${i + 1}`,
          firmwareVersion: `1.0.${i}`,
          firmwareUrl: `https://drive.google.com/example-${i}.bin`,
          updatedAt: date.toLocaleString(),
          nodeId: (i % 5) + 1,
          nodeLocation: i % 2 === 0 ? "Depok Greenhouse" : "Jakarta Greenhouse",
          nodeName: `${i % 2 === 0 ? "depok" : "jakarta"}-node${(i % 5) + 1}-${i % 3 === 0 ? "DHT11" : i % 3 === 1 ? "TDS" : "DS"}`,
          sensorType: i % 3 === 0 ? "DHT11" : i % 3 === 1 ? "TDS" : "DS",
          status: i % 4 === 0 ? "Failed" : "Success",
        };
      });

      setLogs(dummyData);
      setTotalPages(2);
      setTotalData(20);
      setFilterOptions({
        nodeId: [1, 2, 3, 4, 5],
        nodeLocation: ["Depok Greenhouse", "Jakarta Greenhouse"],
        sensorType: ["DHT11", "TDS", "DS"],
        status: ["Success", "Failed"],
      });
    } finally {
      setIsLoading(false);
    }
  };
  // Initial fetch on component mount and when filters or pagination changes
  useEffect(() => {
    fetchLogs();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    currentPage,
    pageSize,
    selectedNodeId,
    selectedLocation,
    selectedSensorType,
    selectedStatus,
  ]);

  // Handle page change
  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  // Filter options for selects
  const nodeIdOptions = [
    { value: "", label: "All Node IDs" },
    ...filterOptions.nodeId.map((id) => ({
      value: id.toString(),
      label: `Node ${id}`,
    })),
  ];

  const locationOptions = [
    { value: "", label: "All Locations" },
    ...filterOptions.nodeLocation.map((location) => ({
      value: location,
      label: location,
    })),
  ];

  const sensorTypeOptions = [
    { value: "", label: "All Sensor Types" },
    ...filterOptions.sensorType.map((type) => ({ value: type, label: type })),
  ];

  const statusOptions = [
    { value: "", label: "All Statuses" },
    ...filterOptions.status.map((status) => ({ value: status, label: status })),
  ];

  // Handle filter changes
  const handleNodeIdChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value ? parseInt(e.target.value) : undefined;
    setSelectedNodeId(value);
    setCurrentPage(1); // Reset to first page when filter changes
  };

  const handleLocationChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value || undefined;
    setSelectedLocation(value);
    setCurrentPage(1);
  };

  const handleSensorTypeChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value || undefined;
    setSelectedSensorType(value);
    setCurrentPage(1);
  };

  const handleStatusChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value || undefined;
    setSelectedStatus(value);
    setCurrentPage(1);
  };

  return (
    <Layout title="Update Logs">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-lokasync-accent">
          Firmware Update Logs
        </h1>
      </div>

      {error && (
        <Alert type="error" message={error} onClose={() => setError("")} />
      )}

      <Card>
        {/* Filters */}
        <div className="mb-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <Select
            label="Node ID"
            options={nodeIdOptions}
            value={selectedNodeId?.toString() || ""}
            onChange={handleNodeIdChange}
          />

          <Select
            label="Location"
            options={locationOptions}
            value={selectedLocation || ""}
            onChange={handleLocationChange}
          />

          <Select
            label="Sensor Type"
            options={sensorTypeOptions}
            value={selectedSensorType || ""}
            onChange={handleSensorTypeChange}
          />

          <Select
            label="Status"
            options={statusOptions}
            value={selectedStatus || ""}
            onChange={handleStatusChange}
          />
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-lokasync-light-green">
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Node ID
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Node Location
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Firmware Version
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Firmware Description
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Sensor Type
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-left">
                  Updated At
                </th>
                <th className="border-b border-lokasync-border px-4 py-2 text-center">
                  Status
                </th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="text-center py-4">
                    <div className="flex justify-center items-center">
                      <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-lokasync-primary"></div>
                      <span className="ml-2">Loading...</span>
                    </div>
                  </td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-4 text-gray-500">
                    No log data found
                  </td>
                </tr>
              ) : (
                logs.map((log, index) => (
                  <tr
                    key={`${log.nodeName}-${log.updatedAt}`}
                    className={index % 2 === 0 ? "bg-white" : "bg-gray-50"}
                  >
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.nodeId}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.nodeLocation}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.firmwareVersion}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.firmwareDescription}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.sensorType}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3">
                      {log.updatedAt}
                    </td>
                    <td className="border-b border-lokasync-border px-4 py-3 text-center">
                      <span
                        className={`inline-block px-2 py-1 rounded-full text-xs font-medium ${
                          log.status === "Success"
                            ? "bg-green-100 text-green-800"
                            : "bg-red-100 text-red-800"
                        }`}
                      >
                        {log.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="mt-4 flex flex-col sm:flex-row justify-between items-center">
          <div className="mb-4 sm:mb-0">
            <p className="text-sm text-gray-500">
              Showing {logs.length > 0 ? (currentPage - 1) * pageSize + 1 : 0} -{" "}
              {Math.min(currentPage * pageSize, totalData)} of {totalData}{" "}
              results
            </p>
          </div>

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={handlePageChange}
          />
        </div>
      </Card>
    </Layout>
  );
};

export default LogPage;
