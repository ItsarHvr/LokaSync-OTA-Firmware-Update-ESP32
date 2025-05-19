import React, { forwardRef } from "react";

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  helperText?: string;
  options: { value: string; label: string }[];
  fullWidth?: boolean;
  required?: boolean;
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  (
    {
      label,
      error,
      helperText,
      options,
      fullWidth = true,
      required = false,
      className = "",
      ...props
    },
    ref,
  ) => {
    const selectClasses = `
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
        <select
          ref={ref}
          className={selectClasses}
          aria-invalid={error ? "true" : "false"}
          {...props}
        >
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        {error && <p className="mt-1 text-sm text-red-500">{error}</p>}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    );
  },
);

Select.displayName = "Select";

export default Select;
