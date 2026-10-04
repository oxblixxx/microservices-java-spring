import http from 'k6/http';
import { check } from 'k6';
import {
  BASE_URL,
  TEST_EMAIL,
  TEST_PASSWORD,
} from './config.js';

export const options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '30m', target: 10 },
    { duration: '2m', target: 0 },
  ],

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1500'],
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
