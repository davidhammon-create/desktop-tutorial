import { clsx } from 'clsx';

const variants = {
  default: 'bg-blue-600 text-white border-transparent',
  secondary: 'bg-gray-200 text-gray-800 border-transparent',
  destructive: 'bg-red-600 text-white border-transparent',
  outline: 'border border-gray-300 text-gray-700',
};

export function Badge({ className, variant = 'default', children, ...props }) {
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
        variants[variant] ?? variants.default,
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}
