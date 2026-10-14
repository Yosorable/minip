export const MinipErrorCode = {
  INVALID_ARGUMENT: "INVALID_ARGUMENT",
  API_NOT_FOUND: "API_NOT_FOUND",
  NOT_SUPPORTED: "NOT_SUPPORTED",
  NOT_FOUND: "NOT_FOUND",
  ALREADY_EXISTS: "ALREADY_EXISTS",
  PERMISSION_DENIED: "PERMISSION_DENIED",
  INVALID_STATE: "INVALID_STATE",
  IO_ERROR: "IO_ERROR",
  DATABASE_ERROR: "DATABASE_ERROR",
  BRIDGE_UNAVAILABLE: "BRIDGE_UNAVAILABLE",
  BRIDGE_ERROR: "BRIDGE_ERROR",
  INVALID_RESPONSE: "INVALID_RESPONSE",
  INTERNAL_ERROR: "INTERNAL_ERROR",
} as const;

export type MinipErrorCode = (typeof MinipErrorCode)[keyof typeof MinipErrorCode];

export interface MinipErrorOptions {
  api?: string;
  details?: Record<string, unknown>;
  cause?: unknown;
}

/** An API or bridge failure. Branch on code, never on the message text. */
export class MinipError extends Error {
  readonly code: string;
  readonly api?: string;
  readonly details?: Record<string, unknown>;
  override readonly cause?: unknown;

  constructor(code: string, message: string, options: MinipErrorOptions = {}) {
    super(message);
    this.name = "MinipError";
    this.code = code;
    this.api = options.api;
    this.details = options.details;
    this.cause = options.cause;
  }
}
