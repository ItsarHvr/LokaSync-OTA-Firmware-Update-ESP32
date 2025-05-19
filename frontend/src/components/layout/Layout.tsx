import { useEffect } from "react";
import type { ReactNode } from "react";
import Header from "./Header";
import Footer from "./Footer";

interface LayoutProps {
  children: ReactNode;
  title: string;
}

const Layout = ({ children, title }: LayoutProps) => {
  // Update document title when title prop changes
  useEffect(() => {
    document.title = `LokaSync | ${title}`;
  }, [title]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-grow py-6">
        <div className="lokasync-container">{children}</div>
      </main>
      <Footer />
    </div>
  );
};

export default Layout;
