function LogoArtboard({ name, tagline, Mark, lockupProps = {} }) {
  const L = window.LogoColors;
  return (
    <div style={{
      width: '100%', height: '100%',
      background: L.cream,
      display: 'grid',
      gridTemplateRows: 'auto 1fr auto auto',
      padding: '24px 28px',
      gap: 16,
      fontFamily: 'Roboto, sans-serif',
      boxSizing: 'border-box',
    }}>
      <div>
        <div style={{font:'500 13px/1 Roboto', color: L.fg2, letterSpacing: 0.4, textTransform:'uppercase'}}>{name}</div>
        <div style={{font:'14px/1.45 Roboto', color: L.fg2, marginTop: 4}}>{tagline}</div>
      </div>

      <div style={{
        display:'flex', alignItems:'center', justifyContent:'center',
        background: '#FFFFFF', border:`1px solid #E4E5DE`, borderRadius: 16,
        padding: 24,
      }}>
        <Mark size={160}/>
      </div>

      <div style={{
        display:'flex', alignItems:'center', justifyContent:'center',
        background: '#FFFFFF', border:`1px solid #E4E5DE`, borderRadius: 12,
        padding: '18px 20px',
      }}>
        <LogoLockup Mark={Mark} {...lockupProps}/>
      </div>

      <div style={{display:'flex', gap: 10}}>
        <div style={{flex:1, background:'#FFFFFF', border:`1px solid #E4E5DE`, borderRadius: 10, padding:'10px 14px', display:'flex', alignItems:'center', gap: 10}}>
          <Mark size={20}/>
          <span style={{font:'500 11px Roboto', color: L.fg2, whiteSpace:'nowrap'}}>favicon · light</span>
        </div>
        <div style={{flex:1, background:'#1A1C18', borderRadius: 10, padding:'10px 14px', display:'flex', alignItems:'center', gap: 10}}>
          <Mark size={20}/>
          <span style={{font:'500 11px Roboto', color: '#F0F1EA', whiteSpace:'nowrap'}}>favicon · dark</span>
        </div>
      </div>
    </div>
  );
}

function LogoCanvasApp() {
  const M = window.LogoMarks;
  const W = 540, H = 460;
  return (
    <DesignCanvas>
      <DCSection id="logo-options" title="Logo options for Amap en Ligne" subtitle="Eight directions · click any artboard to view fullscreen · drag the grip to reorder">
        <DCArtboard id="panier" label="1 · Le Panier" width={W} height={H}>
          <LogoArtboard name="1 · Le Panier" tagline="The basket — central object of every AMAP delivery. Friendly, literal, immediately recognisable." Mark={M.MarkBasket} lockupProps={{style: 'two-tone'}}/>
        </DCArtboard>
        <DCArtboard id="pousse" label="2 · La Pousse" width={W} height={H}>
          <LogoArtboard name="2 · La Pousse" tagline="A young sprout — growth, beginning, the seasonal cycle. Plays well at small sizes." Mark={M.MarkSprout} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
        <DCArtboard id="carotte" label="3 · La Carotte" width={W} height={H}>
          <LogoArtboard name="3 · La Carotte" tagline="Direct continuation of the existing 🥕 emoji. Warm and unambiguous." Mark={M.MarkCarrot} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
        <DCArtboard id="mains" label="4 · Les Mains" width={W} height={H}>
          <LogoArtboard name="4 · Les Mains" tagline="Two hands meeting around a leaf — the producer-consumer relationship at the heart of AMAP." Mark={M.MarkHands} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
        <DCArtboard id="badge" label="5 · Le Cercle" width={W} height={H}>
          <LogoArtboard name="5 · Le Cercle AMAP" tagline="A stamp / seal — institutional weight. Reads as a certification mark." Mark={M.MarkBadge} lockupProps={{style: 'lowercase'}}/>
        </DCArtboard>
        <DCArtboard id="reseau" label="6 · Le Réseau" width={W} height={H}>
          <LogoArtboard name="6 · Le Réseau" tagline="Federated nodes — a leaf at the centre connected to AMAP instances. Speaks to the open-source, federated direction stated in the codebase." Mark={M.MarkNetwork} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
        <DCArtboard id="soleil" label="7 · Le Soleil" width={W} height={H}>
          <LogoArtboard name="7 · Le Soleil" tagline="Sun + leaf — warmth, seasonality, daylight. The most optimistic option." Mark={M.MarkSun} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
        <DCArtboard id="epi" label="8 · L'Épi" width={W} height={H}>
          <LogoArtboard name="8 · L'Épi" tagline="A wheat ear — agricultural classic. More 'producteur' than 'AMAP', leans rustic." Mark={M.MarkWheat} lockupProps={{style: 'amap-bold'}}/>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

window.LogoCanvasApp = LogoCanvasApp;
window.LogoArtboard = LogoArtboard;
