import http from 'k6/http';
import { check } from 'k6';
import {
  BASE_URL,
  TEST_EMAIL,
  TEST_PASSWORD,
} from './config.js';

export const options = {
  vus: 5,
  duration: '30s',

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
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

  check(response, {
    'login returns 200': (r) => r.status === 200,
  });

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
    'patients returns 200': (r) => r.status === 200,
    'patients response is not empty': (r) => r.body.length > 0,
  });
}
