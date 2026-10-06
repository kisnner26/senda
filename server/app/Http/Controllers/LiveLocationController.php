<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LiveLocationController extends Controller
{
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'sentAt' => ['required', 'numeric', 'min:0', 'max:'.(now()->timestamp + 30)],
            'active' => 'required|boolean',
            'position' => 'required_if:active,true|nullable|array:latitude,longitude,accuracy,timestamp',
            'position.latitude' => 'required_if:active,true|numeric|between:-90,90',
            'position.longitude' => 'required_if:active,true|numeric|between:-180,180',
            'position.accuracy' => 'required_if:active,true|numeric|between:0,100000',
            'position.timestamp' => ['required_if:active,true', 'numeric', 'min:'.(now()->timestamp - 90), 'max:'.(now()->timestamp + 30)],
        ]);
        $updated = DB::table('live_locations')->where('id', 1)
            ->where('event_at', '<', $data['sentAt'])->update([
                'event_at' => $data['sentAt'],
                'position' => $data['active'] ? json_encode($data['position'], JSON_THROW_ON_ERROR) : null,
            ]);

        return response()->json(['saved' => $updated === 1]);
    }

    public function show(): JsonResponse
    {
        $live = DB::table('live_locations')->where('id', 1)->first();
        $position = $live?->position ? json_decode($live->position, true, flags: JSON_THROW_ON_ERROR) : null;
        if (! $position || $position['timestamp'] < now()->timestamp - 90) {
            return response()->json(['active' => false]);
        }

        return response()->json(['active' => true, 'position' => $position]);
    }
}
