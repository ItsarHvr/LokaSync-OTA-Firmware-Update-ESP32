# LokaSync Frontend

LokaSync is an agricultural IoT platform that enables firmware updates through Over-The-Air (OTA) for agricultural sensors and nodes. This repository contains the frontend application built with React, Vite, and Tailwind CSS.

## Features

- **Firmware Management**: Upload, edit, and delete firmware for IoT devices
- **OTA Updates**: Push firmware updates to devices over-the-air
- **Real-time Monitoring**: Monitor sensor data in real-time
- **Log Tracking**: View and filter update logs
- **Authentication**: Secure login and registration via Firebase
- **Responsive Design**: Mobile-friendly UI with an agricultural theme

## Tech Stack

- **React + TypeScript**: For building the UI
- **Vite**: For fast development and building
- **Tailwind CSS + Daisy UI**: For styling
- **Chart.js**: For data visualization
- **Firebase**: For authentication
- **MQTT**: For real-time communication with IoT devices

## Project Structure

The project follows a clean architecture approach:

```txt
src/
├── assets/              # Static assets like images
├── components/          # Reusable UI components
│   ├── layout/          # Layout components
│   └── ui/              # UI components
├── contexts/            # React contexts
├── controllers/         # Business logic and API communication
├── firebase/            # Firebase configuration
├── routes/              # Application routes
├── types/               # TypeScript type definitions
├── utils/               # Utility functions
└── views/               # Page components
    ├── auth/            # Authentication pages
    ├── dashboard/       # Dashboard pages
    ├── firmware/        # Firmware management pages
    ├── log/             # Log pages
    ├── monitoring/      # Monitoring pages
    └── profile/         # User profile pages
```

## Getting Started

### Prerequisites

- Node.js (v16 or later)
- Firebase account for authentication
- MQTT broker for real-time communication

### Installation

1. Clone the repository:

```powershell
git clone <repository-url>
cd lokasync-web/frontend
```

2. Install dependencies:

```powershell
npm install
```

3. Set up environment variables:

- Copy `.env.example` to `.env`
- Fill in your Firebase and MQTT configuration

4. Start the development server:

```powershell
npm run dev
```

## Environment Variables

Create a `.env` file in the frontend directory with the following variables:

```txt
# API Configuration
VITE_API_BASE_URL=http://localhost:8000/api

# Firebase Configuration
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-app.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-app.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
VITE_FIREBASE_APP_ID=your-app-id

# MQTT Configuration
VITE_MQTT_BROKER_URL=ws://localhost:9001
VITE_MQTT_USERNAME=lokasync
VITE_MQTT_PASSWORD=iot-password
```

## Building for Production

To build the application for production:

```powershell
npm run build
```

The built files will be in the `dist` directory.

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
