function SearchScreen({ go, preselectedOrg }) {
  const C = window.AmapColors;
  const orgs = [
    { id: 'org-1', name: 'AMAP des Collines',           city: 'Saint-Étienne',  delivery: 'Mercredi 18h' },
    { id: 'org-2', name: 'AMAP du Marais',              city: 'Paris 4e',       delivery: 'Jeudi 19h' },
    { id: 'org-3', name: 'AMAP Jardins Partagés',       city: 'Nantes',         delivery: 'Vendredi 17h30' },
    { id: 'org-4', name: 'AMAP de la Vallée Verte',     city: 'Grenoble',       delivery: 'Mardi 18h30' },
  ];
  const [selected, setSelected] = React.useState(preselectedOrg || '');
  const [firstName, setFirstName] = React.useState('');
  const [lastName, setLastName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [submitting, setSubmitting] = React.useState(false);
  const [done, setDone] = React.useState(false);

  const submit = () => {
    setSubmitting(true);
    setTimeout(() => { setSubmitting(false); setDone(true); }, 800);
  };

  if (done) {
    return (
      <MobileFrame title="Rejoindre une AMAP" onBack={() => go('/')}>
        <div style={{padding: 24, textAlign:'center'}}>
          <span className="material-symbols-outlined" style={{fontSize:64,color:C.green}}>check_circle</span>
          <div style={{font:'400 22px/1.3 Roboto', marginTop: 16}}>Demande envoyée</div>
          <div style={{font:'14px/1.5 Roboto', color: C.fg2, marginTop: 8}}>
            L'AMAP {orgs.find(o => o.id === selected)?.name} vous contactera par email pour valider votre adhésion.
          </div>
          <div style={{marginTop: 24}}><OutlinedButton full onClick={() => go('/')}>RETOUR À L'ACCUEIL</OutlinedButton></div>
        </div>
      </MobileFrame>
    );
  }

  return (
    <MobileFrame title="Rejoindre une AMAP" onBack={() => go('/')}>
      <div style={{padding: 24}}>
        <div style={{font:'400 22px/1.3 Roboto', marginBottom: 8}}>Trouvez une AMAP près de chez vous</div>
        <div style={{font:'14px/1.5 Roboto', color: C.fg2, marginBottom: 16}}>
          Sélectionnez une AMAP puis préinscrivez-vous. Votre coordinateur vous contactera.
        </div>

        <div style={{display:'flex',flexDirection:'column',gap:8, marginBottom: 16}}>
          {orgs.map(org => {
            const on = org.id === selected;
            return (
              <div key={org.id}
                onClick={() => setSelected(org.id)}
                style={{
                  padding: 14, borderRadius: 12,
                  border: `${on?2:1}px solid ${on ? C.primary : C.outlineVariant}`,
                  background: on ? '#F0F8E8' : '#FFFFFF',
                  cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 12,
                }}>
                <span className="material-symbols-outlined" style={{
                  fontSize: 22, color: on ? C.primary : C.fg3,
                }}>{on ? 'radio_button_checked' : 'radio_button_unchecked'}</span>
                <div style={{flex:1}}>
                  <div style={{font:'500 15px/1.3 Roboto', color: C.fg1}}>{org.name}</div>
                  <div style={{font:'12px/1.4 Roboto', color: C.fg2}}>{org.city} · livraison {org.delivery}</div>
                </div>
              </div>
            );
          })}
        </div>

        <SectionHeader>VOS COORDONNÉES</SectionHeader>
        <div style={{display:'flex',flexDirection:'column',gap:12, marginTop: 12}}>
          <TextField label="Prénom *" value={firstName} onChange={setFirstName}/>
          <TextField label="Nom *" value={lastName} onChange={setLastName}/>
          <TextField label="Email *" value={email} onChange={setEmail}/>
        </div>

        <div style={{marginTop: 24}}>
          <FilledButton color={C.blue} full loading={submitting}
            disabled={!selected || !firstName || !lastName || !email}
            onClick={submit}>ENVOYER MA DEMANDE</FilledButton>
        </div>
      </div>
    </MobileFrame>
  );
}

window.SearchScreen = SearchScreen;
