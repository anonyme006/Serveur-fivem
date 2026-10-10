import "iron-session";

declare module "iron-session" {
  interface IronSessionData {
    /** Marker to keep module augmentation non-empty for ESLint */
    __serenityPortal?: true;
  }
}
