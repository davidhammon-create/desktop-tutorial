import * as SliderPrimitive from '@radix-ui/react-slider';
import { clsx } from 'clsx';

export function Slider({ className, ...props }) {
  return (
    <SliderPrimitive.Root
      className={clsx(
        'relative flex w-full touch-none select-none items-center',
        className
      )}
      {...props}
    >
      <SliderPrimitive.Track className="relative h-2 w-full grow overflow-hidden rounded-full bg-gray-200">
        <SliderPrimitive.Range className="absolute h-full bg-blue-600" />
      </SliderPrimitive.Track>
      <SliderPrimitive.Thumb className="block h-5 w-5 rounded-full border-2 border-blue-600 bg-white shadow focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:pointer-events-none disabled:opacity-50" />
    </SliderPrimitive.Root>
  );
}
