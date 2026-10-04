import http from 'k6/http';

export const BASE_URL = (
  __ENV.STAGING_BASE_URL || 'http://localhost:4004'
).replace(/\/$/, '');

export const TEST_EMAIL =
  __ENV.TEST_EMAIL;

export const TEST_PASSWORD =
  __ENV.TEST_PASSWORD;

export function login() {
  return http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    }),
    {
      headers: {
        'Content-Type': 'application/json',
      },
    }
  );
}
