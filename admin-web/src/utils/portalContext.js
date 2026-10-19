import { inject } from "vue";
export const portalKey = Symbol("adminPortal");
export function usePortalContext() {
  const portal = inject(portalKey);
  if (!portal) throw new Error("Portal context is missing.");
  return portal;
}
