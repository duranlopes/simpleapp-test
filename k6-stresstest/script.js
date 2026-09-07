import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8008';

export const options = {
  vus: Number(__ENV.VUS || 5),
  duration: __ENV.DURATION || '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const responses = http.batch([
    ['GET', `${BASE_URL}/health`, null, { tags: { name: 'Health' } }],
    ['GET', `${BASE_URL}/code`, null, { tags: { name: 'Code' } }],
  ]);

  check(responses[0], { 'health returns 200': (response) => response.status === 200 });
  check(responses[1], { 'code returns 200': (response) => response.status === 200 });
  sleep(1);
}
