<?php

namespace App\Http\Controllers;

use Carbon\CarbonImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class TripController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => 'required|uuid',
            'startedAt' => 'required|date',
            'endedAt' => 'required|date|after_or_equal:startedAt',
            'samples' => 'present|array|max:10000',
            'samples.*.id' => 'required|uuid|distinct',
            'samples.*.timestamp' => 'required|date',
            'samples.*.latitude' => 'required|numeric|between:-90,90',
            'samples.*.longitude' => 'required|numeric|between:-180,180',
            'samples.*.accuracy' => 'required|numeric|between:0,100',
            'samples.*.latency' => 'nullable|numeric|between:0,60000',
            'samples.*.quality' => 'required|in:stable,slow,failed,unknown',
            'samples.*.interface' => 'required|string|max:32',
        ]);
        $start = CarbonImmutable::parse($data['startedAt'])->utc();
        $end = CarbonImmutable::parse($data['endedAt'])->utc();
        $previous = $start;
        $samples = [];
        foreach ($data['samples'] as $index => $sample) {
            $time = CarbonImmutable::parse($sample['timestamp'])->utc();
            $success = in_array($sample['quality'], ['stable', 'slow'], true);
            if ($time->lt($previous) || $time->gt($end) || ($success !== isset($sample['latency']))) {
                throw ValidationException::withMessages(["samples.$index" => 'tiempo o resultado de medición inconsistente']);
            }
            $previous = $time;
            $samples[] = [
                'id' => strtolower($sample['id']), 'trip_id' => strtolower($data['id']),
                'timestamp' => $time->format('Y-m-d H:i:s.u'),
                'latitude' => (float) $sample['latitude'], 'longitude' => (float) $sample['longitude'],
                'accuracy' => (float) $sample['accuracy'], 'latency' => $sample['latency'] ?? null,
                'quality' => $sample['quality'], 'interface' => $sample['interface'],
            ];
        }
        $id = strtolower($data['id']);
        $hash = hash('sha256', json_encode([$start->toIso8601String(), $end->toIso8601String(), $samples], JSON_THROW_ON_ERROR));
        $existing = DB::table('trips')->where('id', $id)->first();
        if ($existing) {
            abort_unless(hash_equals($existing->payload_hash, $hash), 409, 'el recorrido ya existe con otros datos');

            return response()->json(['id' => $id, 'saved' => true]);
        }
        try {
            DB::transaction(function () use ($id, $start, $end, $hash, $samples): void {
                DB::table('trips')->insert([
                    'id' => $id, 'started_at' => $start, 'ended_at' => $end, 'payload_hash' => $hash,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                foreach (array_chunk($samples, 300) as $chunk) {
                    DB::table('measurements')->insert($chunk);
                }
            });
        } catch (QueryException $exception) {
            $existing = DB::table('trips')->where('id', $id)->first();
            if (! $existing) {
                // Reused measurement IDs must not partially create a trip.
                abort_if(DB::table('measurements')->whereIn('id', array_column($samples, 'id'))->exists(), 409, 'una medición ya pertenece a otro recorrido');
                throw $exception;
            }
            abort_unless(hash_equals($existing->payload_hash, $hash), 409, 'el recorrido ya existe con otros datos');
        }

        return response()->json(['id' => $id, 'saved' => true], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $trips = DB::table('trips')->orderByDesc('started_at')->paginate(50);

        return response()->json($trips);
    }

    public function show(string $id): JsonResponse
    {
        $trip = DB::table('trips')->where('id', strtolower($id))->first();
        abort_unless($trip, 404);
        $trip->samples = DB::table('measurements')->where('trip_id', $trip->id)->orderBy('timestamp')->get();

        return response()->json($trip);
    }

    public function export(string $id): StreamedResponse
    {
        $json = $this->show($id)->getContent();

        return response()->streamDownload(function () use ($json): void {
            echo $json;
        }, 'senda-'.strtolower($id).'.json', ['Content-Type' => 'application/json']);
    }
}
