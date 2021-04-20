import http from 'k6/http';
import { sleep } from 'k6';
export let options = {
  stages: [
    { duration: '3m', target: 1000 }, // below normal load
    { duration: '1m', target: 1000 },
    { duration: '3m', target: 2000 }, // normal load
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 }, // around the breaking point
    { duration: '5m', target: 300 },
    { duration: '2m', target: 400 }, // beyond the breaking point
    { duration: '5m', target: 400 },
    { duration: '10m', target: 0 }, // scale down. Recovery stage.
  ],
};
export default function () {
  const BASE_URL = 'http://app.prova'; // make sure this is not production
  let responses = http.batch([
    [
      'GET',
      `${BASE_URL}/health`,
      null,
      { tags: { name: 'Health' } },
    ],
    [
      'GET',
      `${BASE_URL}/code`,
      null,
      { tags: { name: 'Code' } },
    ],    
  ]);
  sleep(1);
}