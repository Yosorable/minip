export function uint8ArrayToBase64(
  data: Uint8Array,
  offset: number = 0,
  length: number = 0,
): string {
  if (length === 0) {
    length = data.byteLength;
  }
  const slice =
    offset === 0 && length === data.byteLength
      ? data
      : data.subarray(offset, offset + length);
  let binary = "";
  for (let i = 0; i < slice.byteLength; i++) {
    binary += String.fromCharCode(slice[i]);
  }
  return btoa(binary);
}

export function base64ToUint8Array(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export function base64WriteToUint8Array(
  base64: string,
  buffer: Uint8Array,
  offset: number,
): number {
  const binaryString = atob(base64);
  for (let i = 0; i < binaryString.length; i++) {
    buffer[offset + i] = binaryString.charCodeAt(i);
  }
  return binaryString.length;
}
