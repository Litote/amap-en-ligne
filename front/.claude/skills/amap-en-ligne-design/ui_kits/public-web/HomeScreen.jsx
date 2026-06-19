function HomeScreen({ go }) {
  const C = window.AmapColors;
  const [selected, setSelected] = React.useState('');
  const orgs = [
    { id: 'org-1', name: 'AMAP des Collines' },
    { id: 'org-2', name: 'AMAP du Marais' },
    { id: 'org-3', name: 'AMAP Jardins Partagés' },
    { id: 'org-4', name: 'AMAP de la Vallée Verte' },
  ];

  return (
    <MobileFrame>
      <div style={{padding: '32px 24px'}}>
        {/* Header */}
        <div style={{textAlign:'center', marginBottom: 32}}>
          <img src="../../assets/logo.svg" alt="Amap en Ligne" width="64" height="64" style={{display:'block',margin:'0 auto 8px'}}/>
          <div style={{font:'700 28px/1.2 Roboto', color: C.fg1}}>Amap en ligne</div>
        </div>

        {/* Card 1 — login */}
        <Card style={{marginBottom: 16}}>
          <div style={{font:'500 16px/1.5 Roboto'}}>J'ai déjà un compte</div>
          <div style={{font:'14px/1.43 Roboto', color: C.fg2, marginTop: 4}}>Connectez-vous à votre espace personnel</div>
          <div style={{marginTop: 12}}>
            <FilledButton color={C.green} full onClick={() => go('/login')}>SE CONNECTER</FilledButton>
          </div>
        </Card>

        {/* Card 2 — join an AMAP */}
        <Card style={{marginBottom: 16}}>
          <div style={{font:'500 16px/1.5 Roboto'}}>Je veux rejoindre une AMAP</div>
          <div style={{font:'14px/1.43 Roboto', color: C.fg2, marginTop: 4}}>Préinscrivez-vous</div>
          <div style={{marginTop: 12}}>
            <DropdownField
              label="Choisir une AMAP"
              value={orgs.find(o => o.id === selected)?.name || ''}
              onClick={() => {
                const next = prompt('Choisir : ' + orgs.map((o,i) => `${i+1}. ${o.name}`).join('\n'));
                const idx = parseInt(next) - 1;
                if (orgs[idx]) setSelected(orgs[idx].id);
              }}
            />
          </div>
          <div style={{marginTop: 12}}>
            <FilledButton color={C.blue} full onClick={() => go(selected ? `/amap-search?org=${selected}` : '/amap-search')}>S'INSCRIRE À UNE AMAP</FilledButton>
          </div>
        </Card>

        {/* Card 3 — create */}
        <Card style={{marginBottom: 32}}>
          <div style={{font:'500 16px/1.5 Roboto'}}>Je veux créer une nouvelle organisation</div>
          <div style={{font:'14px/1.43 Roboto', color: C.fg2, marginTop: 4}}>(AMAP ou producteur)<br/>C'est totalement gratuit !</div>
          <div style={{marginTop: 12}}>
            <FilledButton color={C.orange} full onClick={() => go('/register')}>INSCRIVEZ-VOUS</FilledButton>
          </div>
        </Card>

        <div style={{height: 1, background: C.outlineVariant, margin: '8px 0 16px'}}/>

        {/* Info */}
        <div style={{font:'500 14px/1.4 Roboto', color: C.fg1, marginBottom: 8}}>Qu'est-ce qu'une AMAP ?</div>
        <div style={{font:'14px/1.5 Roboto', color: C.fg1}}>
          Les AMAP (Association pour le Maintien d'une Agriculture Paysanne) créent des liens directs entre producteurs et consommateurs autour de produits locaux et de saison.
        </div>
        <div style={{font:'12px/1.4 Roboto', color: C.fg2, marginTop: 16}}>
          Amap en Ligne est gratuit, open-source et auto-hébergeable.
        </div>
      </div>
    </MobileFrame>
  );
}

function DropdownField({ label, value, onClick }) {
  const C = window.AmapColors;
  return (
    <TextField
      label={label}
      value={value || ' '}
      readOnly
      onClick={onClick}
      trailing={<span className="material-symbols-outlined" style={{color: C.fg2}}>arrow_drop_down</span>}
    />
  );
}

window.HomeScreen = HomeScreen;
window.DropdownField = DropdownField;
