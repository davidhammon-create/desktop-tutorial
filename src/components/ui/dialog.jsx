import * as DialogPrimitive from '@radix-ui/react-dialog';
import { clsx } from 'clsx';

export const Dialog = DialogPrimitive.Root;
export const DialogTrigger = DialogPrimitive.Trigger;
export const DialogClose = DialogPrimitive.Close;

function DialogOverlay({ className, ...props }) {
  return (
    <DialogPrimitive.Overlay
      className={clsx(
        'fixed inset-0 z-50 bg-black/50 backdrop-blur-sm',
        'data-[state=open]:animate-in data-[state=closed]:animate-out',
        'data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
        className
      )}
      {...props}
    />
  );
}

export function DialogContent({ className, children, ...props }) {
  return (
    <DialogPrimitive.Portal>
      <DialogOverlay />
      <DialogPrimitive.Content
        className={clsx(
          'fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2',
          'rounded-lg bg-white p-6 shadow-xl',
          'focus:outline-none',
          className
        )}
        {...props}
      >
        {children}
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  );
}

export function DialogHeader({ className, children, ...props }) {
  return (
    <div
      className={clsx('flex flex-col space-y-1.5 text-center sm:text-left mb-4', className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function DialogTitle({ className, children, ...props }) {
  return (
    <DialogPrimitive.Title
      className={clsx('text-lg font-semibold text-gray-900', className)}
      {...props}
    >
      {children}
    </DialogPrimitive.Title>
  );
}

export function DialogDescription({ className, children, ...props }) {
  return (
    <DialogPrimitive.Description
      className={clsx('text-sm text-gray-500', className)}
      {...props}
    >
      {children}
    </DialogPrimitive.Description>
  );
}

export function DialogFooter({ className, children, ...props }) {
  return (
    <div
      className={clsx('flex flex-col-reverse gap-2 sm:flex-row sm:justify-end mt-4', className)}
      {...props}
    >
      {children}
    </div>
  );
}
