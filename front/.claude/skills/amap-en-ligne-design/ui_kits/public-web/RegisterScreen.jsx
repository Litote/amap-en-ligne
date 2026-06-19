function RegisterScreen({ go }) {
  const C = window.AmapColors;
  const [type, setType] = React.useState('amap');
  const [orgName, setOrgName] = React.useState('');
  const [timezone, setTimezone] = React.useState('Europe/Paris');
  const [language, setLanguage] = React.useState('Français');
  const [firstName, setFirstName] = React.useState('');
  const [lastName, setLastName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [terms, setTerms] = React.useState(false);
  const [submitting, setSubmitting] = React.useState(false);
  const [success, setSuccess] = React.useState(null);

  const submit = () => {
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      setSuccess('REQ-' + Math.floor(Math.random() * 90000 + 10000));
    }, 900);
  };

  if (success) {
    return (
      <MobileFrame title="Nouvelle Organisation" onBack={() => go('/')}>
        <div style={{maxWidth: 480, margin: '0 auto', padding: 24, textAlign:'center'}}>
          <span className="material-symbols-outlined" style={{fontSize: 64, color: C.green}}>check_circle</span>
          <div style={{font:'400 22px/1.27 Roboto', color: C.fg1, marginTop: 16}}>
            Demande de création d'organisation soumise
          </div>
          <div style={{font:'14px/1.5 Roboto', color: C.fg1, marginTop: 8}}>
            Un email de confirmation vous a été envoyé.<br/>
            Délai de traitement habituel : moins de 3 jours ouvrés.
          </div>
          <div style={{font:'12px/1.4 Roboto', color: C.fg2, marginTop: 8}}>
            Référence : {success}
          </div>

          <Card style={{marginTop: 24, textAlign:'left'}}>
            <div style={{font:'500 14px/1.4 Roboto', marginBottom: 8}}>Prochaines étapes :</div>
            <div style={{font:'14px/1.6 Roboto'}}>1. Examen de votre demande par notre équipe</div>
            <div style={{font:'14px/1.6 Roboto'}}>2. Activation de votre organisation</div>
            <div style={{font:'14px/1.6 Roboto'}}>3. Accès à votre espace d'administration</div>
          </Card>

          <div style={{marginTop: 24}}>
            <OutlinedButton full onClick={() => go('/')}>RETOUR À L'ACCUEIL</OutlinedButton>
          </div>
        </div>
      </MobileFrame>
    );
  }

  return (
    <MobileFrame title="Nouvelle Organisation" onBack={() => go('/')}>
      <div style={{maxWidth: 480, margin: '0 auto', padding: 24}}>
        <div style={{font:'400 22px/1.27 Roboto', color: C.fg1}}>
          Créer une nouvelle organisation
        </div>
        <div style={{font:'14px/1.5 Roboto', color: C.fg3, marginTop: 8}}>
          Votre demande sera examinée par notre équipe. Vous recevrez une confirmation par email sous 3 jours ouvrés.
        </div>

        <SectionHeader>INFORMATIONS ORGANISATION</SectionHeader>

        <div style={{font:'14px/1.4 Roboto', color: C.fg1, marginBottom: 8}}>Type d'organisation *</div>
        <SegmentedButton
          options={[{value:'amap',label:'AMAP'},{value:'producer',label:'Producteur'}]}
          value={type}
          onChange={setType}
        />

        <div style={{display:'flex',flexDirection:'column',gap:12, marginTop: 12}}>
          <TextField
            label={type === 'amap' ? "Nom de l'AMAP *" : "Nom du producteur *"}
            value={orgName} onChange={setOrgName}
          />
          <TextField label="Fuseau horaire *" value={timezone} readOnly
            trailing={<span className="material-symbols-outlined" style={{color: C.fg2}}>arrow_drop_down</span>}
            onClick={() => {}}
          />
          <TextField label="Langue par défaut *" value={language} readOnly
            trailing={<span className="material-symbols-outlined" style={{color: C.fg2}}>arrow_drop_down</span>}
            onClick={() => setLanguage(language === 'Français' ? 'English' : 'Français')}
          />
        </div>

        <SectionHeader>COMPTE ADMINISTRATEUR DE L'ORGANISATION</SectionHeader>

        <div style={{display:'flex',flexDirection:'column',gap:12, marginTop: 12}}>
          <TextField label="Prénom *" value={firstName} onChange={setFirstName}/>
          <TextField label="Nom *" value={lastName} onChange={setLastName}/>
          <TextField label="Email *" value={email} onChange={setEmail}/>
        </div>

        <div style={{marginTop: 24}}>
          <CheckboxTile checked={terms} onChange={setTerms}>
            J'accepte les conditions d'utilisation du service
          </CheckboxTile>
        </div>

        <div style={{display:'flex', gap: 12, marginTop: 16}}>
          <div style={{flex:1}}>
            <OutlinedButton full onClick={() => go('/')}>ANNULER</OutlinedButton>
          </div>
          <div style={{flex:1}}>
            <FilledButton color={C.green} full
              disabled={!terms || !orgName || !email}
              loading={submitting}
              onClick={submit}>CRÉER</FilledButton>
          </div>
        </div>
      </div>
    </MobileFrame>
  );
}

window.RegisterScreen = RegisterScreen;
