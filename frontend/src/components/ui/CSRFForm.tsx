import type { FormEvent, ReactNode } from "react";
import { useCSRF } from "../../contexts";

interface CSRFFormProps {
  children: ReactNode;
  onSubmit: (e: FormEvent) => void;
  className?: string;
}

/**
 * A form component that automatically includes CSRF protection
 * Use this component instead of a regular form element for all forms that submit data
 */
const CSRFForm = ({ children, onSubmit, className = "" }: CSRFFormProps) => {
  const { getToken } = useCSRF();

  const handleSubmit = (e: FormEvent) => {
    // Let the parent component handle the actual submission
    onSubmit(e);
  };

  return (
    <form onSubmit={handleSubmit} className={className}>
      {/* Hidden input field with CSRF token */}
      <input type="hidden" name="csrf_token" value={getToken()} />

      {children}
    </form>
  );
};

export default CSRFForm;
