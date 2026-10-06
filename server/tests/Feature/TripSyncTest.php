<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class TripSyncTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['senda.token_hash' => password_hash('test-private-token', PASSWORD_DEFAULT)]);
    }

    private function payload(): array
    {
        return [
            'id' => (string) Str::uuid(), 'startedAt' => '2026-10-06T08:00:00Z', 'endedAt' => '2026-10-06T08:01:00Z',
            'samples' => [[
                'id' => (string) Str::uuid(), 'timestamp' => '2026-10-06T08:00:12Z',
                'latitude' => 12.125, 'longitude' => -86.278, 'accuracy' => 8,
                'latency' => 120, 'quality' => 'stable', 'interface' => 'móvil',
            ]],
        ];
    }

    public function test_routes_are_private_and_fail_closed_without_configuration(): void
    {
        $this->getJson('/api/trips')->assertUnauthorized();
        $this->get('/')->assertRedirect('/login');
        $this->getJson('/data/trips')->assertRedirect('/login');
        config(['senda.token_hash' => '']);
        $this->withToken('test-private-token')->getJson('/api/trips')->assertStatus(503);
    }

    public function test_sync_is_idempotent_and_conflicting_payloads_do_not_overwrite(): void
    {
        $payload = $this->payload();
        $this->withToken('test-private-token')->postJson('/api/trips', $payload)->assertCreated();
        $this->postJson('/api/trips', $payload)->assertOk();
        $this->getJson('/api/trips/'.$payload['id'])->assertOk()->assertJsonPath('samples.0.quality', 'stable');
        $this->post('/login', ['token' => 'test-private-token'])->assertRedirect('/');
        $this->get('/data/trips/'.$payload['id'].'/export')->assertDownload('senda-'.strtolower($payload['id']).'.json');
        $this->assertDatabaseCount('trips', 1);
        $this->assertDatabaseCount('measurements', 1);
        $payload['samples'][0]['latitude'] = 12.2;
        $this->postJson('/api/trips', $payload)->assertConflict();
        $this->assertDatabaseHas('measurements', ['latitude' => 12.125]);
    }

    public function test_invalid_coordinates_and_results_are_rejected(): void
    {
        $payload = $this->payload();
        $payload['samples'][0]['latitude'] = 91;
        $this->withToken('test-private-token')->postJson('/api/trips', $payload)->assertUnprocessable();
        $payload['samples'][0]['latitude'] = 12;
        $payload['samples'][0]['quality'] = 'failed';
        $this->postJson('/api/trips', $payload)->assertUnprocessable();
        $payload['samples'][0]['latency'] = null;
        $this->postJson('/api/trips', $payload)->assertCreated();
    }

    public function test_samples_cannot_escape_the_recording_window(): void
    {
        $payload = $this->payload();
        $payload['samples'][0]['timestamp'] = '2026-10-06T09:00:00Z';
        $this->withToken('test-private-token')->postJson('/api/trips', $payload)->assertUnprocessable();
        $this->assertDatabaseCount('trips', 0);
    }

    public function test_reusing_measurement_ids_rolls_back_the_entire_trip(): void
    {
        $payload = $this->payload();
        $this->withToken('test-private-token')->postJson('/api/trips', $payload)->assertCreated();
        $payload['id'] = (string) Str::uuid();
        $this->postJson('/api/trips', $payload)->assertConflict();
        $this->assertDatabaseCount('trips', 1);
    }

    public function test_web_session_login_logout_and_token_rotation(): void
    {
        $this->post('/login', ['token' => 'bad'])->assertSessionHasErrors('token');
        $this->post('/login', ['token' => 'test-private-token'])->assertRedirect('/');
        $this->get('/')->assertOk();
        $this->getJson('/data/trips')->assertOk()->assertHeader('Cache-Control', 'no-store, private');
        config(['senda.token_hash' => password_hash('rotated-token', PASSWORD_DEFAULT)]);
        $this->get('/')->assertRedirect('/login');
        $this->post('/logout')->assertRedirect('/login');
        $this->get('/')->assertRedirect('/login');
    }
}
