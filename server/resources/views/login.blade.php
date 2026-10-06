@extends('layout')
@section('content')
<main class="login-shell">
<a class="wordmark" href="/">senda<span aria-hidden="true">↗</span></a>
<section class="login-panel">
<p class="eyebrow">archivo privado / acceso</p><h1>tu red,<br>en el camino.</h1>
<div class="login-dial" aria-hidden="true"><span>↗</span><i></i></div>
<form method="post" action="/login" class="login-form">
@csrf
<label for="token">token privado</label>
<input id="token" name="token" type="password" required maxlength="128" autocomplete="current-password" placeholder="el mismo que guardaste en senda" @error('token') aria-invalid="true" aria-describedby="token-error" @enderror>
@error('token')<p id="token-error" class="form-error" role="alert">{{ $message }}</p>@enderror
<button class="primary" type="submit">entrar al territorio <span aria-hidden="true">↗</span></button>
</form>
<p class="fine-print">los recorridos son tuyos. este mapa solo se abre con tu token.</p>
</section>
<footer class="login-footer"><span>la conexión también tiene geografía.</span><span>registro / 01</span></footer>
</main>
@endsection
