import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL } from './config.js';

export const options = {
  vus: 5,
  duration: '30s',

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/actuator/health`);

  check(response, {
    'health returns 200': (r) => r.status === 200,
    'health response is not empty': (r) => r.body.length > 0,
  });
}
