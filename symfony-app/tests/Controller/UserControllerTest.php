<?php

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpClient\MockHttpClient;
use Symfony\Component\HttpClient\Response\MockResponse;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use App\Service\UserApiClient;

class UserControllerTest extends WebTestCase
{
    public function testIndex()
    {
        $client = static::createClient();

        $mockApiClient = $this->createMock(UserApiClient::class);
        $mockApiClient->method('getUsers')->willReturn([
            'data' => [
                ['id' => 1, 'first_name' => 'Jan', 'last_name' => 'Kowalski', 'gender' => 'male', 'birthdate' => '1990-01-01']
            ],
            'meta' => ['total_count' => 1, 'page' => 1, 'page_size' => 10]
        ]);

        // Replace the UserApiClient in the container
        $client->getContainer()->set(UserApiClient::class, $mockApiClient);

        $crawler = $client->request('GET', '/users');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'User List');
        $this->assertSelectorTextContains('td:nth-child(2)', 'Jan');
    }
}
