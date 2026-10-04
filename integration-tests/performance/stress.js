import http from 'k6/http';
import { check } from 'k6';
import {
  BASE_URL,
  TEST_EMAIL,
  TEST_PASSWORD,
} from './config.js';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 10 },
    { duration: '1m', target: 25 },
    { duration: '1m', target: 50 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],

  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
  },
};

export function setup() {
  const response = http.post(
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

  if (response.status !== 200) {
    throw new Error(`Login failed: HTTP ${response.status}`);
  }

  const body = response.json();

  if (!body.token) {
    throw new Error('Login response does not contain token');
  }

  return {
    token: body.token,
  };
}

export default function (data) {
  const response = http.get(
    `${BASE_URL}/api/patients`,
    {
      headers: {
        Authorization: `Bearer ${data.token}`,
      },
      tags: {
        endpoint: 'patients',
      },
    }
  );

  check(response, {
    'patients endpoint responds': (r) => r.status === 200,
  });
}
