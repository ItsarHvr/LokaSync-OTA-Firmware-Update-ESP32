import React, { forwardRef } from "react";

interface TextareaProps
  extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
  fullWidth?: boolean;
  required?: boolean;
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  (
    {
      label,
      error,
      helperText,
      fullWidth = true,
      required = false,
      className = "",
      ...props
    },
    ref,
  ) => {
    const textareaClasses = `
    lokasync-input
    ${error ? "border-red-500 focus:border-red-500" : "border-gray-300 focus:border-lokasync-primary"}
    ${fullWidth ? "w-full" : ""}
    ${className}
  `;

    return (
      <div className={`mb-6 ${fullWidth ? "w-full" : ""}`}>
        {label && (
          <label className="block text-gray-700 mb-1">
            {label} {required && <span className="text-red-500">*</span>}
          </label>
        )}
        <textarea
          ref={ref}
          className={textareaClasses}
          aria-invalid={error ? "true" : "false"}
          {...props}
        />
        {error && <p className="mt-1 text-sm text-red-500">{error}</p>}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    );
  },
);

Textarea.displayName = "Textarea";

export default Textarea;
