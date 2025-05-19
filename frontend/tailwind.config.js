/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        white: "#ffffff",
        black: "#000000",
        gray: {
          500: "#6b7280",
          600: "#4b5563",
        },
        green: {
          500: "#10b981",
        },
        red: {
          500: "#ef4444",
        },
        lokasync: {
          "light-green": "#e6ffee", // Light green background color
          border: "#d1e0d1", // Slightly darker border color
          primary: "#22c55e", // Primary green color for buttons, etc.
          secondary: "#16a34a", // Secondary green for hover states
          accent: "#15803d", // Darker green for accents
        },
      },
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        lokasync: {
          primary: "#22c55e",
          secondary: "#16a34a",
          accent: "#15803d",
          neutral: "#d1e0d1",
          "base-100": "#ffffff",
          info: "#3abff8",
          success: "#36d399",
          warning: "#fbbd23",
          error: "#f87272",
        },
      },
    ],
  },
};
