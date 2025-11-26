<?php

namespace App\Service;

use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class UserApiClient
{
    public function __construct(
        private HttpClientInterface $client,
        #[Autowire(env: 'PHOENIX_API_URL')]
        private string $apiUrl
    ) {
    }

    public function getUsers(array $params = []): array
    {
        $response = $this->client->request('GET', $this->apiUrl . '/users', [
            'query' => $params
        ]);
        return $response->toArray();
    }

    public function getUser(int $id): array
    {
        $response = $this->client->request('GET', $this->apiUrl . '/users/' . $id);
        return $response->toArray()['data'];
    }

    public function createUser(array $data): array
    {
        $response = $this->client->request('POST', $this->apiUrl . '/users', [
            'json' => ['user' => $data]
        ]);
        return $response->toArray();
    }

    public function updateUser(int $id, array $data): array
    {
        $response = $this->client->request('PUT', $this->apiUrl . '/users/' . $id, [
            'json' => ['user' => $data]
        ]);
        return $response->toArray();
    }

    public function deleteUser(int $id): void
    {
        $this->client->request('DELETE', $this->apiUrl . '/users/' . $id);
    }

    public function importUsers(): array
    {
        $response = $this->client->request('POST', $this->apiUrl . '/import', [
            'headers' => [
                'x-api-token' => 'secret-token'
            ]
        ]);
        return $response->toArray();
    }
}
