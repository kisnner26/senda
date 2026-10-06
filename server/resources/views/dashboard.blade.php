@extends('layout')
@section('content')
<div class="shell" id="dashboard">
<header class="site-header">
<a class="wordmark" href="/" aria-label="senda, inicio">senda<span aria-hidden="true">↗</span></a>
<p class="header-note">un atlas personal<br>de tu conexión.</p>
<nav aria-label="navegación principal"><a href="#territorio">territorio</a><a href="#archivo">archivo</a><form method="post" action="/logout">@csrf<button type="submit" class="quiet">salir <span aria-hidden="true">↗</span></button></form></nav>
</header>
<main>
<div class="page-caption"><span>observatorio de red / personal</span><span id="today"></span></div>
<div class="notice" id="status" role="status" aria-live="polite">cargando tus recorridos…</div>
<div class="spread" id="territorio">
<section class="overview" aria-labelledby="overview-title">
<div class="section-top"><span class="eyebrow">01 / estabilidad</span><span class="small-dot" aria-hidden="true"></span></div>
<h1 id="overview-title">tu red,<br>en el camino.</h1>
<div class="dial" id="dial" role="img" aria-label="sin mediciones"><div class="dial-ticks" aria-hidden="true"></div><div class="dial-pointer" aria-hidden="true"><i></i></div><div class="dial-label"><strong id="stability">—</strong><span>con internet</span></div></div>
<div class="metric-grid">
<div class="pulse-panel"><div class="panel-heading"><h2>pulso de<br>la conexión</h2><span aria-hidden="true">↗</span></div><div class="bars" id="bars" role="img" aria-label="sin tiempos de respuesta"></div><div class="chart-axis"><span>inicio</span><span id="sample-count">0 pruebas</span><span>fin</span></div></div>
<div class="side-metrics"><div class="latency"><strong id="latency">—</strong><span>ms / mediana</span></div><a class="map-link" href="#route-map">ver el rastro <span aria-hidden="true">↗</span></a></div>
</div>
<div class="overview-footer"><span id="trip-date">sin recorridos todavía</span><span id="distance">0.00 km</span></div>
</section>
<section class="territory" aria-labelledby="map-title">
<div class="section-top"><span class="eyebrow">02 / territorio</span><button id="fit-map" class="icon-button" aria-label="centrar el mapa en el recorrido">↗</button></div>
<div class="territory-heading"><h2 id="map-title">donde la red<br>pierde el hilo.</h2><span class="coordinates" id="coordinates">sin ubicación</span></div>
<p class="live-status" id="live-status" role="status" hidden></p><div class="map-frame"><div id="route-map" aria-label="mapa de las mediciones del recorrido"></div><div class="map-empty" id="map-empty"><span aria-hidden="true">↗</span><strong>el territorio espera.</strong><p>inicia un recorrido desde tu iphone<br>y sincronízalo para verlo aquí.</p></div><div class="map-caption">rastro / <span id="map-points">0</span> puntos</div></div>
<ul class="legend" aria-label="leyenda del mapa"><li><i class="stable"></i>estable</li><li><i class="slow"></i>lenta</li><li><i class="failed"></i>fallo</li><li><i class="unknown"></i>sin datos</li></ul>
<div class="territory-stats"><div><span>zonas sospechosas</span><strong id="zones">00</strong></div><p>dos fallos seguidos dejan una marca.<br>un hueco sin datos no cuenta como caída.</p></div>
</section>
</div>
<section class="archive" id="archivo" aria-labelledby="archive-title">
<div class="archive-heading"><div><p class="eyebrow">03 / archivo</p><h2 id="archive-title">cada vuelta deja un rastro.</h2></div><button class="outline" id="export" disabled>exportar recorrido <span aria-hidden="true">↓</span></button></div>
<div id="trip-list" class="trip-list" aria-label="recorridos disponibles"></div>
<div class="archive-empty" id="archive-empty"><p>ningún recorrido guardado.</p><span>los que termines y sincronices desde el iphone aparecerán aquí.</span></div>
<div class="archive-controls"><button class="quiet" id="refresh">actualizar <span aria-hidden="true">↻</span></button><button class="quiet" id="next-page" hidden>más recorridos <span aria-hidden="true">→</span></button><button class="quiet" id="demo">explorar una demostración</button></div>
</section>
</main>
<footer class="site-footer"><span>la conexión también tiene geografía.</span><span>mediciones https / sin intensidad de señal</span><span>senda / 2026</span></footer>
</div>
@endsection
