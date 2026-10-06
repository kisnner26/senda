import L from 'leaflet';
if (document.getElementById('dashboard')) initialize();
async function initialize() {
    const $ = id => document.getElementById(id);
    const colors = {stable:'#101510',slow:'#f16e20',failed:'#983526',unknown:'#535e54'};
    const labels = {stable:'estable',slow:'lenta',failed:'fallo de conexión',unknown:'sin datos'};
    let current=null, trips=[], nextPage=null, isDemo=false, busy=false;
    const map=L.map('route-map',{scrollWheelZoom:false}).setView([12.126,-86.271],13);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,attribution:'&copy; <a href="https://www.openstreetmap.org/copyright">openstreetmap</a>'})
        .on('tileerror',()=>{if(current)status('las calles no pudieron cargar; las mediciones siguen visibles.',true)}).addTo(map);
    const layer=L.featureGroup().addTo(map);
    const liveLayer=L.featureGroup().addTo(map);
    let livePosition=null, liveExpires=0, liveBusy=false, liveCentered=false;
    function clearLive(){livePosition=null;liveLayer.clearLayers();$('live-status').hidden=true;$('map-empty').hidden=!!current?.samples.length;liveCentered=false}
    async function loadLive(){
        if(liveBusy||document.hidden||isDemo)return;
        liveBusy=true;
        try{
            const live=await request('/data/live');
            if(!live.active){clearLive();return}
            const fix=live.position, age=Date.now()/1000-fix.timestamp;
            if(age>90){clearLive();return}
            livePosition=fix;liveExpires=(fix.timestamp+90)*1000;liveLayer.clearLayers();
            const point=[fix.latitude,fix.longitude];
            L.circle(point,{radius:fix.accuracy,color:colors.slow,weight:1,fillOpacity:0.12}).addTo(liveLayer);
            const label=document.createElement('span');label.textContent=`iphone en vivo / ± ${fmt(fix.accuracy)} m`;
            L.circleMarker(point,{radius:7,color:'#fff',weight:3,fillColor:colors.slow,fillOpacity:1}).bindTooltip(label).addTo(liveLayer);
            $('live-status').textContent=`en vivo / ± ${fmt(fix.accuracy)} m / ${new Date(fix.timestamp*1000).toLocaleTimeString('es-NI')}`;
            $('live-status').hidden=false;$('map-empty').hidden=true;
            if(!liveCentered&&!current?.samples.length){map.fitBounds(liveLayer.getBounds(),{padding:[35,35],maxZoom:16,animate:false})}
            liveCentered=true;
        }catch{if(Date.now()>=liveExpires)clearLive()}
        finally{liveBusy=false}
    }
    const date=v=>new Date(v.includes('T')?v:v.replace(' ','T')+'Z');
    const fmt=(v,d=0)=>new Intl.NumberFormat('es-NI',{minimumFractionDigits:d,maximumFractionDigits:d}).format(v);
    const time=v=>new Intl.DateTimeFormat('es-NI',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}).format(date(v)).toLowerCase();
    $('today').textContent=new Intl.DateTimeFormat('es-NI',{day:'2-digit',month:'short',year:'numeric'}).format(new Date()).toLowerCase();
    for(let i=0;i<12;i++){const tick=document.createElement('i');tick.className='tick';tick.style.transform=`rotate(${i*30}deg)`;$('dial').querySelector('.dial-ticks').append(tick)}
    function status(message,error=false){$('status').textContent=message;$('status').className=error?'notice error':isDemo?'notice demo-notice':'notice'}
    async function request(url){const response=await fetch(url,{headers:{Accept:'application/json'},cache:'no-store'});if(response.redirected||response.status===401)throw Error('tu sesión terminó. vuelve a entrar con tu token.');if(!response.ok)throw Error('no se pudieron cargar los recorridos. intenta actualizar.');return response.json()}
    function metrics(trip){
        const samples=trip.samples, measured=samples.filter(s=>s.quality!=='unknown');
        const values=samples.filter(s=>s.latency!=null).map(s=>Number(s.latency)).sort((a,b)=>a-b);
        let zones=0,run=0,distance=0;
        samples.forEach((sample,i)=>{const previous=samples[i-1],adjacent=!previous||date(sample.timestamp)-date(previous.timestamp)<=45000;
            if(sample.quality==='failed'){run=adjacent?run+1:1;if(run===2)zones++}else run=0;
            if(previous&&adjacent)distance+=map.distance([sample.latitude,sample.longitude],[previous.latitude,previous.longitude]);
        });
        const mid=Math.floor(values.length/2);
        return{stability:measured.length?measured.filter(s=>s.quality!=='failed').length/measured.length:null,median:values.length?(values.length%2?values[mid]:(values[mid-1]+values[mid])/2):null,zones,distance,count:measured.length};
    }
    function fit(){if(livePosition){map.fitBounds(liveLayer.getBounds(),{padding:[30,30],maxZoom:16,animate:false});return}if(layer.getLayers().length)map.fitBounds(layer.getBounds(),{padding:[30,30],maxZoom:16,animate:false})}
    function draw(trip){
        current=trip;const m=metrics(trip);
        $('stability').textContent=m.stability===null?'—':fmt(m.stability*100)+'%';
        $('dial').style.setProperty('--angle',`${(m.stability??0)*360}deg`);
        $('dial').setAttribute('aria-label',m.stability===null?'sin mediciones':`internet disponible en ${fmt(m.stability*100)} por ciento de las pruebas`);
        $('latency').textContent=m.median===null?'—':fmt(m.median);$('sample-count').textContent=m.count+' pruebas';$('zones').textContent=String(m.zones).padStart(2,'0');
        $('distance').textContent=fmt(m.distance/1000,2)+' km';$('trip-date').textContent=time(trip.started_at);$('map-points').textContent=trip.samples.length;
        $('map-empty').hidden=trip.samples.length>0||!!livePosition;$('export').disabled=false;$('bars').replaceChildren();
        const barAverages=Array.from({length:7},(_,b)=>{const values=trip.samples.slice(Math.floor(b*trip.samples.length/7),Math.floor((b+1)*trip.samples.length/7)).filter(s=>s.latency!=null).map(s=>Number(s.latency));
            return values.length?values.reduce((a,v)=>a+v,0)/values.length:null;});
        const ceiling=Math.max(200,...barAverages.filter(v=>v!==null));
        barAverages.forEach((avg,b)=>{const bar=document.createElement('div');
            bar.className=`bar${b===3?' active':''}${avg===null?' empty':''}`;bar.style.height=avg===null?'4px':Math.max(12,Math.min(100,avg/ceiling*100))+'%';$('bars').append(bar);
        });
        $('bars').setAttribute('aria-label','tiempos de respuesta del recorrido; los huecos indican ausencia de resultados válidos');layer.clearLayers();
        trip.samples.forEach((sample,i)=>{const point=[Number(sample.latitude),Number(sample.longitude)],previous=trip.samples[i-1];
            if(previous&&sample.quality!=='unknown'&&previous.quality!=='unknown'&&date(sample.timestamp)-date(previous.timestamp)<=45000)L.polyline([[previous.latitude,previous.longitude],point],{color:colors[sample.quality],weight:5,dashArray:sample.quality==='slow'?'8 4':sample.quality==='failed'?'2 4':undefined}).addTo(layer);
            const popup=document.createElement('div');popup.textContent=`${labels[sample.quality]} / ${sample.latency==null?'sin respuesta':fmt(sample.latency)+' ms'} / ${time(sample.timestamp)}`;
            L.circleMarker(point,{radius:sample.quality==='failed'?5:3,color:'#fff',weight:1,fillColor:colors[sample.quality],fillOpacity:1,dashArray:sample.quality==='unknown'?'2 2':undefined}).bindPopup(popup).addTo(layer);
        });
        const first=trip.samples[0];$('coordinates').textContent=first?`${Number(first.latitude).toFixed(4)} ${first.latitude<0?'s':'n'}\n${Math.abs(Number(first.longitude)).toFixed(4)} ${first.longitude<0?'o':'e'}`:'sin ubicación';fit();
        document.querySelectorAll('.trip-button').forEach(button=>{const selected=button.dataset.id===trip.id;button.classList.toggle('selected',selected);button.setAttribute('aria-pressed',String(selected))});
    }
    async function select(trip){if(busy)return;busy=true;$('dashboard').setAttribute('aria-busy','true');
        try{const full=trip.samples?trip:await request('/data/trips/'+encodeURIComponent(trip.id));trips=trips.map(item=>item.id===full.id?full:item);draw(full);list();status(isDemo?'demostración / datos ficticios. tus recorridos siguen intactos.':'recorrido sincronizado desde tu iphone.');}
        catch(error){status(error.message,true)}finally{busy=false;$('dashboard').setAttribute('aria-busy','false')}
    }
    function list(){
        $('trip-list').replaceChildren();$('archive-empty').hidden=trips.length>0;
        trips.forEach((trip,index)=>{const button=document.createElement('button');button.className='trip-button';button.dataset.id=trip.id;button.setAttribute('aria-pressed',String(current?.id===trip.id));if(current?.id===trip.id)button.classList.add('selected');
            const m=trip.samples?metrics(trip):null;
            const cells=[['trip-number',String(index+1).padStart(2,'0')],['trip-date',time(trip.started_at),isDemo?'recorrido de demostración':'registro del iphone'],['trip-quality',m?.stability!=null?fmt(m.stability*100)+'%':'↗','abrir rastro'],['trip-zones',m?String(m.zones).padStart(2,'0'):'—','zonas sospechosas'],['trip-duration',fmt(Math.max(0,(date(trip.ended_at)-date(trip.started_at))/60000))+' min','duración'],['trip-arrow','↗']];
            cells.forEach(([className,value,subtitle])=>{const cell=document.createElement('span');cell.className=className;const text=document.createElement(subtitle&&className!=='trip-date'?'strong':'span');text.textContent=value;cell.append(text);if(subtitle){const small=document.createElement('small');small.textContent=subtitle;cell.append(small)}button.append(cell)});
            button.addEventListener('click',()=>select(trip));$('trip-list').append(button);
        });
    }
    async function load(append=false){isDemo=false;status('cargando tus recorridos…');
        try{const page=await request(append&&nextPage?nextPage:'/data/trips');trips=append?[...trips,...page.data]:page.data;nextPage=page.next_page_url?'/data/trips?page='+(page.current_page+1):null;$('next-page').hidden=!nextPage;
            if(trips.length){await select(trips[0]);list()}else{draw({id:'',started_at:new Date().toISOString(),samples:[]});current=null;$('trip-date').textContent='sin recorridos todavía';$('export').disabled=true;list();status('todo listo. sincroniza tu primer recorrido desde el iphone.')}
        }catch(error){status(error.message,true)}
    }
    function demo(){clearLive();isDemo=true;nextPage=null;$('next-page').hidden=true;const start=Date.now()-1440000;
        trips=[{id:'demostración',started_at:new Date(start).toISOString(),ended_at:new Date(start+1080000).toISOString(),samples:Array.from({length:90},(_,i)=>{const failed=(i>=37&&i<=42)||(i>=66&&i<=68);return{timestamp:new Date(start+i*12000).toISOString(),latitude:12.125+i*.00004+Math.sin(i/8)*.00012,longitude:-86.278+i*.00008,accuracy:8,quality:failed?'failed':i%9===0?'slow':'stable',latency:failed?null:i%9===0?950:85+i%13*8,interface:'móvil'}})}];
        draw(trips[0]);list();status('demostración / datos ficticios. actualizar vuelve a tus recorridos.');
    }
    $('fit-map').addEventListener('click',fit);$('refresh').addEventListener('click',()=>load());$('next-page').addEventListener('click',()=>load(true));$('demo').addEventListener('click',demo);
    $('export').addEventListener('click',()=>{if(!current)return;if(!isDemo){window.location.assign('/data/trips/'+encodeURIComponent(current.id)+'/export');return}const url=URL.createObjectURL(new Blob([JSON.stringify(current,null,2)],{type:'application/json'}));const link=document.createElement('a');link.href=url;link.download=isDemo?'senda-demostracion.json':'senda-'+current.id+'.json';link.hidden=true;document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000)});
    await load();
    await loadLive();
    setInterval(()=>{if(livePosition&&Date.now()>=liveExpires)clearLive();void loadLive()},12000);
    document.addEventListener('visibilitychange',()=>{if(!document.hidden){if(Date.now()>=liveExpires)clearLive();void loadLive()}});
}
