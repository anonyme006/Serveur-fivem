/// <reference types="vite/client" />

interface Window {
  invokeNative?: (native: string, arg: string) => void;
  GetParentResourceName?: () => string;
}
