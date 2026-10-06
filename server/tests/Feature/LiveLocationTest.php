<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LiveLocationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['senda.token_hash' => password_hash('test-private-token', PASSWORD_DEFAULT)]);
    }

    private function payload(): array
    {
        return ['sentAt' => now()->timestamp, 'active' => true, 'position' => [
            'latitude' => 12.125, 'longitude' => -86.278, 'accuracy' => 250,
            'timestamp' => now()->timestamp,
        ]];
    }

    public function test_live_location_requires_authentication(): void
    {
        $this->getJson('/api/live')->assertUnauthorized();
        $this->putJson('/api/live', ['active' => false, 'sentAt' => 1])->assertUnauthorized();
        $this->getJson('/data/live')->assertRedirect('/login');
        $this->assertDatabaseHas('live_locations', ['id' => 1, 'position' => null]);
    }

    public function test_position_is_private_and_expires_after_ninety_seconds(): void
    {
        $this->freezeTime();
        $payload = $this->payload();
        $this->withToken('test-private-token')->getJson('/api/live')->assertExactJson(['active' => false]);
        $this->putJson('/api/live', $payload)->assertJsonPath('saved', true);
        $this->assertDatabaseMissing('live_locations', ['id' => 1, 'position' => null]);
        $this->getJson('/api/live')->assertExactJson(['active' => true, 'position' => $payload['position']])
            ->assertHeader('Cache-Control', 'no-store, private');
        $this->post('/login', ['token' => 'test-private-token'])->assertRedirect('/');
        $this->getJson('/data/live')->assertJsonPath('active', true);
        $this->travel(91)->seconds();
        $this->getJson('/api/live')->assertExactJson(['active' => false]);
    }

    public function test_disabling_removes_coordinates_and_rejects_a_delayed_update(): void
    {
        $this->freezeTime();
        $payload = $this->payload();
        $this->withToken('test-private-token')->putJson('/api/live', $payload)->assertJsonPath('saved', true);
        $this->travel(1)->seconds();
        $this->putJson('/api/live', ['sentAt' => now()->timestamp, 'active' => false])->assertJsonPath('saved', true);
        $this->putJson('/api/live', $payload)->assertJsonPath('saved', false);
        $this->getJson('/api/live')->assertExactJson(['active' => false]);
        $this->assertDatabaseHas('live_locations', ['id' => 1, 'position' => null]);
    }

    public function test_invalid_coordinates_stale_fixes_and_future_events_are_rejected(): void
    {
        $this->freezeTime();
        $payload = $this->payload();
        $payload['position']['latitude'] = 91;
        $this->withToken('test-private-token')->putJson('/api/live', $payload)->assertJsonValidationErrors('position.latitude');
        $payload = $this->payload();
        $payload['position']['timestamp'] -= 91;
        $this->putJson('/api/live', $payload)->assertJsonValidationErrors('position.timestamp');
        $payload = $this->payload();
        $payload['sentAt'] += 31;
        $this->putJson('/api/live', $payload)->assertJsonValidationErrors('sentAt');
        $this->putJson('/api/live', ['active' => true, 'sentAt' => now()->timestamp])->assertJsonValidationErrors('position');
        $this->assertDatabaseHas('live_locations', ['id' => 1, 'position' => null]);
    }
}
