import { BrowserRouter } from "react-router-dom";
import AppRoutes from "./routes/AppRoutes";
import { AuthProvider, CSRFProvider } from "./contexts";
import "./App.css";

function App() {
  return (
    <BrowserRouter>
      <CSRFProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </CSRFProvider>
    </BrowserRouter>
  );
}

export default App;
